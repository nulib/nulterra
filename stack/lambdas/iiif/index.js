const AWS                  = require('aws-sdk');
const IIIF                 = require('iiif-processor');
const authorize            = require('./lib/authorize');
const cookie               = require('cookie');
const isObject             = require('lodash.isobject');
const isString             = require('lodash.isstring');
const MiddleAuth           = require('./lib/middle_auth');
const middy                = require('@middy/core');
const cors                 = require('@middy/http-cors');
const noWaitEventLoop      = require('@middy/do-not-wait-for-empty-event-loop');
const httpHeaderNormalizer = require('@middy/http-header-normalizer');

const tiffBucket           = process.env.tiff_bucket;

async function s3Object(id, callback) {
  let s3 = new AWS.S3();
  let path = id.match(/.{1,2}/g).join('/');
  let request = s3.getObject({ 
    Bucket: tiffBucket, 
    Key: `${path}-pyramid.tif`, 
  })
  let stream = request
    .createReadStream()
    .on('error', (err, _resp) => { 
      console.log(
        'SWALLOWING UNCATCHABLE S3 ERROR', 
        `${err.statusCode} / ${err.code} / ${err.message}`
      );
    });

  try {
    return await callback(stream);
  } finally {
    stream.end().destroy();
    request.abort();
  }
}

async function dimensions (id) {
  let s3 = new AWS.S3();
  let path = id.match(/.{1,2}/g).join('/');
  const obj = await s3.headObject({
    Bucket: tiffBucket,
    Key: `${path}-pyramid.tif`
  }).promise()
  if (obj.Metadata.width && obj.Metadata.height) {
    return {
      width: parseInt(obj.Metadata.width, 10),
      height: parseInt(obj.Metadata.height, 10)
    }
  }
  return null;
}

function getEventHeader(event, name) {
  if (event.headers && event.headers[name]) {
    return event.headers[name];
  } else if (event.multiValueHeaders && event.multiValueHeaders[name]) {
    return event.multiValueHeaders[name][0];
  } else {
    return undefined;
  }
}

function makeResource(event) {
  let scheme = getEventHeader(event, 'x-forwarded-proto') || 'http';
  let host = getEventHeader(event, 'x-forwarded-host') || getEventHeader(event, 'host');
  let path = decodeURI(event.path.replace(/%2f/gi, ''));
  if (!/\.(jpe?g|tiff?|gif|png|json)$/.test(path)) {
    path = path + '/info.json';
  }
  if (process.env.include_stage) {
    path = '/' + event.requestContext.stage + path;
  }
  let uri = `${scheme}://${host}${path}`;
  
  return new IIIF.Processor(uri, s3Object, dimensions);
}

function packageBase64(result) {
  let base64Payload = result.body.toString('base64');
  return {
    statusCode: 200,
    headers: { 'content-type': result.contentType },
    isBase64Encoded: true,
    body: base64Payload
  };
}

function packageRaw(result) {
  return {
    statusCode: 200,
    headers: { 'content-type': result.contentType },
    isBase64Encoded: false,
    body: result.body
  };
}

function packageResponse(result) {
  if (/^image\//.test(result.contentType)) {
    return packageBase64(result);
  } else {
    return packageRaw(result);
  }
}

function getAuthToken(event) {
  let authHeader = getEventHeader(event, 'authorization');
  if (isString(authHeader)) {
    return authHeader.replace(/^Bearer /,'');
  }
  
  let cookieHeader = getEventHeader(event, 'cookie');
  if (isString(cookieHeader)) {
    let cookies = cookie.parse(cookieHeader);
    if (isObject(cookies) && isString(cookies.IIIFAuthToken)) {
      return cookies.IIIFAuthToken;
    }
  }

  return null;
}

function processRequest(event, context, callback) {
  AWS.config.region = context.invokedFunctionArn.match(/^arn:aws:lambda:(\w+-\w+-\d+):/)[1];

  if (event.httpMethod == 'OPTIONS' || event.path == '/iiif/login') {
    callback(null, { statusCode: 204, body: null });
  } else {
    let resource = makeResource(event);
    let authToken = getAuthToken(event);
    authorize(authToken, resource.id, event.headers.referer)
      .catch(err => { callback(err) })
      .then(authed => {
          if (resource.filename == 'info.json' || authed) {
            resource.execute()
              .then(result => {
                callback(null, packageResponse(result));
              })
              .catch(err => {
                if (err.statusCode) {
                  callback(null, { statusCode: err.statusCode, headers: { 'content-type': 'text/plain' }, body: 'Not Found' });
                } else if (err instanceof resource.errorClass) {
                  callback(null, { statusCode: 400, headers: { 'content-type': 'text/plain' }, body: err.toString() });
                } else {
                  callback(err, null);
                }
              });
          } else {
            callback(null, { statusCode: 403, headers: { 'content-type': 'text/plain' }, body: 'Unauthorized' });
          }
      })
  }
}

module.exports = {
  handler: middy(processRequest)
            .use(noWaitEventLoop())
            .use(httpHeaderNormalizer())
            .use(cors({ headers: 'authorization, cookie', credentials: true }))
            .use(MiddleAuth)
};
