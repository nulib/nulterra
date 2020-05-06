const AWS                  = require('aws-sdk');
const IIIF                 = require('iiif-processor');
const authorize            = require('./lib/authorize');
const isString             = require('lodash.isstring');
const MiddleAuth           = require('./lib/middle_auth');
const middy                = require('@middy/core');
const cors                 = require('@middy/http-cors');
const httpHeaderNormalizer = require('@middy/http-header-normalizer');

const tiffBucket           = process.env.tiff_bucket;

function s3Object(id) {
  var s3 = new AWS.S3();
  var path = id.match(/.{1,2}/g).join('/');
  return s3.getObject({ 
    Bucket: tiffBucket, 
    Key: `${path}-pyramid.tif`, 
  }).createReadStream();
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
  var scheme = getEventHeader(event, 'x-forwarded-proto') || 'http';
  var host = getEventHeader(event, 'x-forwarded-host') || getEventHeader(event, 'host');
  var path = event.path.replace(/%2f/gi, '');
  if (!/\.(jpg|tif|gif|png|json)$/.test(path)) {
    path = path + '/info.json';
  }
  if (process.env.include_stage) {
    path = '/' + event.requestContext.stage + path;
  }
  var uri = `${scheme}://${host}${path}`;
  
  let s3Handler = id => {
    return s3Object(id).on('error', (err, _resp) => { 
      console.log('SWALLOWING UNCATCHABLE S3 ERROR', `${err.statusCode} / ${err.code} / ${err.message}`);
    });
  };
  return new IIIF.Processor(uri, s3Handler, dimensions);
}

function packageBase64(result) {
  var base64Payload = result.body.toString('base64');
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

function processRequest(event, context, callback) {
  context.callbackWaitsForEmptyEventLoop = false;
  AWS.config.region = context.invokedFunctionArn.match(/^arn:aws:lambda:(\w+-\w+-\d+):/)[1];

  if (event.httpMethod == 'OPTIONS' || event.path == '/iiif/login') {
    callback(null, { statusCode: 204, body: null });
  } else {
    var authToken = isString(event.headers.authorization) ? event.headers.authorization.replace(/^Bearer /,'') : null;
    var resource = makeResource(event);
    authorize(authToken, resource.id, event.headers.Referer)
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
            .use(httpHeaderNormalizer())
            .use(cors({ headers: 'authorization, cookie', credentials: true }))
            .use(MiddleAuth)
};
