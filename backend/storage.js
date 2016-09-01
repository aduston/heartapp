"use strict"

var AWS = require('aws-sdk');

var ddb = null
var s3 = new AWS.S3()
var cloudfront = new AWS.CloudFront()

exports.getDDB = function() {
  if (!ddb) {
    var service = new AWS.DynamoDB()
    ddb = new AWS.DynamoDB.DocumentClient({ service: service });
  }
  return ddb
};

exports.initForTesting = function(callback) {
  callback(null, "done");
};

/**
 * Saves this object into S3 at the given key. The object will have
 * public visibility. Since the bucket is the main Cloudfront origin, 
 * it will also be publicly accessible at https://adamsheart.com/{key}
 *
 * Body can be text or a buffer.
 */
exports.saveObject = function(key, body, contentType, callback) {
  callback(null, "done");
};

exports.invalidatePath = function(path, callback) {
  callback(null, "done");
};
