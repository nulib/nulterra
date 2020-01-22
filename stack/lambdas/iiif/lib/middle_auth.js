const isObject = require('lodash.isobject');
const isString = require('lodash.isstring');
const cookie   = require('cookie');

function authCookie(handler) {
  var cookieHeader = handler.event.headers['Cookie'] || '';
  var result = cookie.parse(cookieHeader).IIIFAuthToken;
  return result;
}

const MiddleAuth = {
  before: (handler, next) => {
    if (!isObject(handler.event.headers)) {
      handler.event.headers = {};
    }
    if (!isString(handler.event.headers['Authorization'])) {
      var token = authCookie(handler);
      if (isString(token)) {
        handler.event.headers['Authorization'] = `Bearer ${token}`
      }
    }
    next();
  },

  after: (handler, next) => {
    if (isString(handler.event.headers['Authorization'])) {
      var cookieToken = authCookie(handler);
      var token = handler.event.headers['Authorization'].replace(/^Bearer/, '').trim();
      if (token != cookieToken) {
        if (!isObject(handler.response.headers)) {
          handler.response.headers = {};
        }
        var cookieOptions = { domain: process.env.auth_domain };
        if (token == '') {
          token = 'deleted';
          cookieOptions.maxAge = -1;
        }
        handler.response.headers['Set-Cookie'] = cookie.serialize('IIIFAuthToken', token, cookieOptions);
      }
    }
    next();
  },

  onError: (handler, next) => {
    console.log('ERROR', handler.error);
    next();
  }
}

module.exports = MiddleAuth;
