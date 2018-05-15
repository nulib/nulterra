const AWS = require('aws-sdk');
const uuid = require('uuid/v4');
const crypto = require('crypto-js');

exports.handler = (event, context, callback) => {
  AWS.config.region = context.invokedFunctionArn.match(/^arn:aws:lambda:(\w+-\w+-\d+):/)[1];

  var bucket = event.Records[0].s3.bucket.name
  var key = event.Records[0].s3.object.key
  var manifest = "s3://" + bucket + "/" + key
  var message = {
    "job_class": process.env.JobClassName,
    "job_id": uuid(),
    "queue_name": "batch_ingest",
    "arguments": [manifest],
    "locale":"en"
  }

  var sqs = new AWS.SQS();
  var body = JSON.stringify(message);
  var digest = crypto.HmacSHA1(body,process.env.Secret).toString();
  var params = {
    MessageBody: body,
    QueueUrl: process.env.QueueUrl,
    MessageDeduplicationId: message['job_id'],
    MessageGroupId: context.invokedFunctionArn,
    MessageAttributes: {
      "origin": { DataType: "String", StringValue: "AEJ" },
      "message-digest": { DataType: "String", StringValue: digest }
    }
  };
  sqs.sendMessage(params, callback);
}
