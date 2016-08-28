"use strict"

var AWS = require('aws-sdk');

var ddb = null

exports.getDDB = function() {
  if (!ddb) {
    var service = new AWS.DynamoDB()
    ddb = new AWS.DynamoDB.DocumentClient({ service: service });
  }
  return ddb
};

/**
 * Saves this object into S3 at the given key. The object will have
 * public visibility. Since the bucket is the main Cloudfront origin, 
 * it will also be publicly accessible at https://adamsheart.com/{key}
 */
exports.saveObject = function(key, text) {
  
};
