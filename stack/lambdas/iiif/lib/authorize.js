const isObject = require('lodash.isobject');
const isString = require('lodash.isstring');
const fetch    = require('node-fetch');
const jwt      = require('jsonwebtoken');
const url      = require('url');
const AWS      = require('aws-sdk');

const apiTokenSecret = process.env.api_token_secret;
const elasticSearch  = process.env.elastic_search;

function getCurrentUser(token) {
  if (isString(token)) {
    try {
      return jwt.verify(token, apiTokenSecret);
    } catch(err) {
      return null;
    }
  } else {
    return null;
  }
}

async function fetchJson(request) {
  return new Promise((resolve, reject) => {
    var client = new AWS.HttpClient();
    client.handleRequest(request, null, (response) => {
      var responseBody = '';
      response.on('data', (chunk) => { 
        responseBody += chunk; 
      });
      response.on('end', () => { 
        response.body = responseBody;
        response.json = JSON.parse(responseBody);
        resolve(response);
      });
    }, (error) => reject(error));
  });
}

async function makeRequest(method, requestUrl, body = null) {
  return new Promise((resolve, reject) => {
    var chain = new AWS.CredentialProviderChain();
    var request = new AWS.HttpRequest(requestUrl, 'us-east-1');
    request.method = method;
    request.headers['Host'] = url.parse(requestUrl).host;
    request.body = body;
    request.headers['Content-Type'] = 'application/json';

    chain.resolve((err, credentials) => { 
      if (err) {
        console.log('WARNING: ', err);
        console.log('Returning unsigned request');
      } else {
        var signer = new AWS.Signers.V4(request, 'es');
        signer.addAuthorization(credentials, new Date());
      }
      resolve(request);
    });
  });
}

async function authorize(token, id) {
  if (process.env.allow_everything) {
    return true;
  }
  
  var currentUser = getCurrentUser(token);
  var docUrl = url.parse(url.resolve(elasticSearch, `common/_doc/${id}`));
  var request = await makeRequest('GET', docUrl);
  var response = await fetchJson(request);
  var doc = response.json;

  if (isObject(doc._source) && isString(doc._source.visibility)) {
    switch(doc._source.visibility) {
      case 'open':          return true;
      case 'authenticated': return isObject(currentUser);
      case 'restricted':    return false;
    }
  }
  return false;
}

module.exports = authorize;