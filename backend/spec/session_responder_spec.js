"use strict"

var utils = require('./helpers/utils');
var storage = require('../storage');
var schema = require('../schema');
var AWS = require('aws-sdk');
var async = require('async');

describe("session_responder", function() {
  var sessionResponder = require('../session_responder');
  var storageObj = null;

  beforeEach(function(done) {
    AWS.config.update({ region: 'us-east-1c' });
    AWS.config.dynamodb = { endpoint: 'http://localhost:8000' };
    async.parallel([
      function(callback) {
        schema.deleteAndCreateLocal(callback);
      },
      function(callback) {
        storageObj = storage.initForTesting(callback);
      }
    ], done);
  });

  it("saves a record", function(done) {
    async.waterfall([
      utils.uniqueNumber,
      function(uniqueNumber, callback) {
        sessionResponder.handler(
          {
            timestamp: 123123,
            observations: "AAAAUwAAAFYAAAFZAAACXA=="
          }, null, callback);
      },
      function(result, callback) {
        storage.getDDB().get({
          TableName: "HeartSessions",
          Key: {
            SessionShard: 0,
            SessionTimestamp: 123123
          },
          ConsistentRead: true
        }, callback);
      }
    ], function(err, result) {
      console.log("Error", err);
      console.log("Result", result);
      done();
    });
  });
});
