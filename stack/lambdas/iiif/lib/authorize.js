const isObject = require('lodash.isobject');
const isString = require('lodash.isstring');
const jwt      = require('jsonwebtoken');
const url      = require('url');
const AWS      = require('aws-sdk');

const apiTokenSecret = process.env.api_token_secret;
const elasticSearch  = process.env.elastic_search;
const allowedFrom    = allowedFromRegexes(process.env.allow_from);

function allowedFromRegexes(str) {
  var configValues = isString(str) ? str.split(';') : [];
  var result = [];
  for (var re in configValues) {
    result.push(new RegExp(configValues[re]));
  }
  return result;
}

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
    }, (error) => {
      console.log("ERROR RETRIEVING AUTH DOCUMENT: ", error);
      resolve(null);
    });
  });
}

async function makeRequest(method, requestUrl, body = null) {
  return new Promise((resolve, reject) => {
    var chain = new AWS.CredentialProviderChain();
    var request = new AWS.HttpRequest(requestUrl, AWS.config.region);
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

async function authorize(token, id, referer) {
  for (var re in allowedFrom) {
    if (allowedFrom[re].test(referer)) return true;
  }

  var currentUser = getCurrentUser(token);
  var doc = await getDoc(id);

  switch(visibility(doc._source)) {
    case 'open':          return true;
    case 'authenticated': return isObject(currentUser);
    case 'restricted':    return false;
  }
  return false;
}

async function getDoc(id) {
  var response = await getDocFromIndex(id, 'meadow');
  if (response.statusCode == 200) {
    return response.json;
  }
  response = await getDocFromIndex(id, 'common');
  return response.json
}

async function getDocFromIndex(id, index) {
  var docUrl = url.parse(url.resolve(elasticSearch, `${index}/_doc/${id}`));
  var request = await makeRequest('GET', docUrl);
  return await fetchJson(request);
}

function visibility(source) {
  if (!isObject(source)) return null;

  if (isObject(source.visibility)) {
    return source.visibility.id.toLowerCase();
  } else if (isString(source.visibility)) {
    return source.visibility.toLowerCase();
  }

  return null;
}

module.exports = authorize;