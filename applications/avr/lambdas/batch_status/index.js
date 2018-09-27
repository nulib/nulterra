const AWS = require('aws-sdk');
const uuid = require('uuid/v4');
const crypto = require('crypto-js');

exports.handler = (event, context, callback) => {
  AWS.config.region = context.invokedFunctionArn.match(/^arn:aws:lambda:(\w+-\w+-\d+):/)[1];

  var message = {
    "job_class": process.env.JobClassName,
    "job_id": uuid(),
    "queue_name": "batch_ingest",
    "locale":"en"
  }

  var sqs = new AWS.SQS();
  var body = JSON.stringify(message);
  var digest = crypto.HmacSHA1(body,process.env.Secret).toString();
  var params = {
    MessageBody: body,
    QueueUrl: process.env.QueueUrl,
    MessageAttributes: {
      "origin": { DataType: "String", StringValue: "AEJ" },
      "message-digest": { DataType: "String", StringValue: digest }
    }
  };
  if (process.env.QueueUrl.match(/\.fifo$/)) {
    params.MessageDeduplicationId = message['job_id']
    params.MessageGroupId = context.invokedFunctionArn
  }
  sqs.sendMessage(params, callback);
}
