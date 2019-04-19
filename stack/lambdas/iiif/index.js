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

function processRequest(event, context, callback) {
  AWS.config.region = context.invokedFunctionArn.match(/^arn:aws:lambda:(\w+-\w+-\d+):/)[1];

  if (event.httpMethod == 'OPTIONS' || event.path == '/iiif/login') {
    callback(null, { statusCode: 204, body: null });
  } else {
    var authToken = isString(event.headers.Authorization) ? event.headers.Authorization.replace(/^Bearer /,'') : null;
    var resource = makeResource(event);
    authorize(authToken, resource.id)
      .then(authed => {
          if (resource.filename == 'info.json' || authed) {
            resource.execute()
              .then(result => {
                var response = { 
                  statusCode: 200, 
                  headers: { 'Content-Type': result.contentType }, 
                  isBase64Encoded: /^image\//.test(result.contentType)
                };
                if (response.isBase64Encoded) {
                  response.body = result.body.toString('base64');
                } else {
                  response.body = result.body;
                }
                callback(null, response);
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
