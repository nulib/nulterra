const AWS        = require('aws-sdk');
const IIIF       = require('iiif');
const authorize  = require('./lib/authorize');
const isString   = require('lodash.isstring');
const middy      = require('middy');
const MiddleAuth = require('./lib/middle_auth');
const { 
  cors,
  httpHeaderNormalizer
} = require('middy/middlewares');

const tiffBucket     = process.env.tiff_bucket;

function s3Object(id) {
  var s3 = new AWS.S3();
  var path = id.match(/.{1,2}/g).join('/');
  return s3.getObject({ 
    Bucket: tiffBucket, 
    Key: `${path}-pyramid.tif`, 
  }).createReadStream();
}

function makeResource(event) {
  var scheme = event.headers['X-Forwarded-Proto'] || 'http';
  var host = event.headers['Host'];
  var path = event.path.replace(/%2f/gi, '');
  if (!/\.(jpg|tif|gif|png|json)$/.test(path)) {
    path = path + '/info.json';
  }
  if (process.env.include_stage) {
    path = '/' + event.requestContext.stage + path;
  }
  var uri = `${scheme}://${host}${path}`;
  
  return new IIIF.Processor(uri, id => s3Object(id));
}

function packageBase64(result) {
  var base64Payload = result.body.toString('base64');
  return {
    statusCode: 200,
    headers: { 'Content-Type': result.contentType },
    isBase64Encoded: true,
    body: base64Payload
  };
}

function packageRaw(result) {
  return {
    statusCode: 200,
    headers: { 'Content-Type': result.contentType },
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
  AWS.config.region = context.invokedFunctionArn.match(/^arn:aws:lambda:(\w+-\w+-\d+):/)[1];

  if (event.httpMethod == 'OPTIONS' || event.path == '/iiif/login') {
    callback(null, { statusCode: 204, body: null });
  } else {
    var authToken = isString(event.headers.Authorization) ? event.headers.Authorization.replace(/^Bearer /,'') : null;
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
                  callback(null, { statusCode: err.statusCode, headers: { 'Content-Type': 'text/plain' }, body: 'Not Found' });
                } else if (err instanceof resource.errorClass) {
                  callback(null, { statusCode: 400, headers: { 'Content-Type': 'text/plain' }, body: err.toString() });
                } else {
                  callback(err, null);
                }
              });
          } else {
            callback(null, { statusCode: 403, headers: { 'Content-Type': 'text/plain' }, body: 'Unauthorized' });
          }
      })
  }
}

module.exports = {
  handler: middy(processRequest)
            .use(httpHeaderNormalizer())
            .use(cors({ headers: 'Authorization, Cookie', credentials: true }))
            .use(MiddleAuth)
};
