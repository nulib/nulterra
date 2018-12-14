{
  "openapi": "3.0.1",
  "info": {
    "title": "${api_name}",
    "version": "2018-12-12T21:11:02Z"
  },
  "servers": [
    {
      "url": "https://${hostname}"
    }
  ],
  "paths": {
    "/public/{proxy+}": {
      "options": {
        "responses": {
          "200": {
            "description": "200 response",
            "headers": {
              "Access-Control-Allow-Origin": {
                "schema": {
                  "type": "string"
                }
              },
              "Access-Control-Allow-Methods": {
                "schema": {
                  "type": "string"
                }
              },
              "Access-Control-Allow-Headers": {
                "schema": {
                  "type": "string"
                }
              }
            },
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/Empty"
                }
              }
            }
          }
        },
        "x-amazon-apigateway-integration": {
          "responses": {
            "default": {
              "statusCode": "200",
              "responseParameters": {
                "method.response.header.Access-Control-Allow-Methods": "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
                "method.response.header.Access-Control-Allow-Headers": "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'",
                "method.response.header.Access-Control-Allow-Origin": "'*'"
              }
            }
          },
          "requestTemplates": {
            "application/json": "{\"statusCode\": 200}"
          },
          "passthroughBehavior": "when_no_match",
          "type": "mock"
        }
      },
      "x-amazon-apigateway-any-method": {
        "parameters": [
          {
            "name": "proxy",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "x-amazon-apigateway-integration": {
          "uri": "${public_manifest_url}/{proxy}",
          "responses": {
            "default": {
              "statusCode": "200"
            }
          },
          "requestParameters": {
            "integration.request.path.proxy": "method.request.path.proxy"
          },
          "passthroughBehavior": "when_no_match",
          "httpMethod": "ANY",
          "cacheNamespace": "nd967c",
          "cacheKeyParameters": [
            "method.request.path.proxy"
          ],
          "type": "http_proxy"
        }
      }
    },
    "/iiif/login": {
      "post": {
        "parameters": [
          {
            "name": "Authorization",
            "in": "header",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "200 response",
            "headers": {
              "Set-Cookie": {
                "schema": {
                  "type": "string"
                }
              }
            },
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/Empty"
                }
              }
            }
          },
          "204": {
            "description": "204 response",
            "headers": {
              "Set-Cookie": {
                "schema": {
                  "type": "string"
                }
              }
            },
            "content": {}
          }
        },
        "x-amazon-apigateway-integration": {
          "uri": "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "responses": {
            "default": {
              "statusCode": "200"
            }
          },
          "passthroughBehavior": "when_no_match",
          "httpMethod": "POST",
          "contentHandling": "CONVERT_TO_TEXT",
          "type": "aws_proxy"
        }
      },
      "options": {
        "responses": {
          "200": {
            "description": "200 response",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/Empty"
                }
              }
            }
          }
        },
        "x-amazon-apigateway-integration": {
          "uri": "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "responses": {
            "default": {
              "statusCode": "200"
            }
          },
          "passthroughBehavior": "when_no_match",
          "httpMethod": "POST",
          "contentHandling": "CONVERT_TO_TEXT",
          "type": "aws_proxy"
        }
      }
    },
    "/iiif/2/{id}/{proxy+}": {
      "get": {
        "parameters": [
          {
            "name": "proxy",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "Cookie",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "Origin",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "Authorization",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "200 response",
            "headers": {
              "Access-Control-Allow-Origin": {
                "schema": {
                  "type": "string"
                }
              },
              "Access-Control-Allow-Credentials": {
                "schema": {
                  "type": "string"
                }
              },
              "Set-Cookie": {
                "schema": {
                  "type": "string"
                }
              },
              "Access-Control-Allow-Headers": {
                "schema": {
                  "type": "string"
                }
              }
            },
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/Empty"
                }
              }
            }
          }
        },
        "x-amazon-apigateway-integration": {
          "uri": "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "responses": {
            "default": {
              "statusCode": "200",
              "responseParameters": {
                "method.response.header.Access-Control-Allow-Origin": "'*'"
              },
              "contentHandling": "CONVERT_TO_BINARY"
            }
          },
          "passthroughBehavior": "when_no_match",
          "httpMethod": "POST",
          "cacheNamespace": "frz8df",
          "cacheKeyParameters": [
            "method.request.path.proxy"
          ],
          "contentHandling": "CONVERT_TO_TEXT",
          "type": "aws_proxy"
        }
      },
      "options": {
        "parameters": [
          {
            "name": "proxy",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "Origin",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "Authorization",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "200 response",
            "headers": {
              "Access-Control-Allow-Origin": {
                "schema": {
                  "type": "string"
                }
              },
              "Access-Control-Allow-Credentials": {
                "schema": {
                  "type": "string"
                }
              },
              "Access-Control-Allow-Headers": {
                "schema": {
                  "type": "string"
                }
              }
            },
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/Empty"
                }
              }
            }
          }
        },
        "x-amazon-apigateway-integration": {
          "uri": "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "responses": {
            "default": {
              "statusCode": "200"
            }
          },
          "passthroughBehavior": "when_no_match",
          "httpMethod": "POST",
          "cacheNamespace": "frz8df",
          "cacheKeyParameters": [
            "method.request.path.proxy"
          ],
          "contentHandling": "CONVERT_TO_TEXT",
          "type": "aws_proxy"
        }
      }
    },
    "/iiif/2/{id}/info.json": {
      "get": {
        "parameters": [
          {
            "name": "Cookie",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "Origin",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "Authorization",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "200 response",
            "headers": {
              "Access-Control-Allow-Origin": {
                "schema": {
                  "type": "string"
                }
              },
              "Access-Control-Allow-Credentials": {
                "schema": {
                  "type": "string"
                }
              },
              "Set-Cookie": {
                "schema": {
                  "type": "string"
                }
              },
              "Access-Control-Allow-Headers": {
                "schema": {
                  "type": "string"
                }
              }
            },
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/Empty"
                }
              }
            }
          }
        },
        "x-amazon-apigateway-integration": {
          "uri": "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "responses": {
            "default": {
              "statusCode": "200",
              "responseParameters": {
                "method.response.header.Access-Control-Allow-Origin": "'*'"
              }
            }
          },
          "passthroughBehavior": "when_no_match",
          "httpMethod": "POST",
          "contentHandling": "CONVERT_TO_TEXT",
          "type": "aws_proxy"
        }
      },
      "options": {
        "parameters": [
          {
            "name": "Origin",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "Authorization",
            "in": "header",
            "schema": {
              "type": "string"
            }
          },
          {
            "name": "id",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "200 response",
            "headers": {
              "Access-Control-Allow-Origin": {
                "schema": {
                  "type": "string"
                }
              },
              "Access-Control-Allow-Credentials": {
                "schema": {
                  "type": "string"
                }
              },
              "Access-Control-Allow-Headers": {
                "schema": {
                  "type": "string"
                }
              }
            },
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/Empty"
                }
              }
            }
          }
        },
        "x-amazon-apigateway-integration": {
          "uri": "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "responses": {
            "default": {
              "statusCode": "200"
            }
          },
          "passthroughBehavior": "when_no_match",
          "httpMethod": "POST",
          "contentHandling": "CONVERT_TO_TEXT",
          "type": "aws_proxy"
        }
      }
    }
  },
  "components": {
    "schemas": {
      "Empty": {
        "title": "Empty Schema",
        "type": "object"
      }
    }
  },
  "x-amazon-apigateway-binary-media-types": [
    "*/*"
  ]
}