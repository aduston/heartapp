"use strict"

var AWS = require('aws-sdk');

var ddb = null
var s3 = new AWS.S3()
var cloudfront = new AWS.CloudFront()

let S3_BUCKET = 'adamsheart-site';
let CLOUDFRONT_ID = 'E2QVTW8XZXK8E7';

var testingStorageObj = null;

exports.getDDB = function() {
  if (!ddb) {
    var service = new AWS.DynamoDB()
    ddb = new AWS.DynamoDB.DocumentClient({ service: service });
  }
  return ddb
};

exports.initForTesting = function(callback) {
  testingStorageObj = {
    savedObjects: [],
    invalidatedPaths: []
  };
  callback(null, testingStorageObj);
};

/**
 * Saves this object into S3 at the given key. The object will have
 * public visibility. Since the bucket is the main Cloudfront origin, 
 * it will also be publicly accessible at https://adamsheart.com/{key}
 *
 * Body can be text or a buffer.
 */
exports.saveObject = function(key, body, contentType, callback) {
  if (testingStorageObj != null) {
    testingStorageObj.savedObjects.push({ key: key, body: body, contentType: contentType });
    callback(null, "okay");
  } else {
    var params = {
      Bucket: S3_BUCKET,
      Key: key,
      ACL: 'public-read',
      Body: body,
      ContentType: contentType
    };
    s3.putObject(params, callback);
  }
};

exports.invalidatePath = function(path, callback) {
  if (testingStorageObj != null) {
    testingStorageObj.invalidatedPaths.push(path);
    callback(null, "done");
  } else {
    // TODO: invalidate in cloudfront
    var params = {
      DistributionId: CLOUDFRONT_ID,
      InvalidationBatch: {
        CallerReference: ('' + new Date().getTime()),
        Paths: {
          Quantity: 1,
          Items: [path]
        }
      }
    };
    cloudfront.createInvalidation(params, callback);
  }
};
