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
        storage.initForTesting(function(err, result) {
          storageObj = result;
          callback(err, result);
        });
      }
    ], done);
  });

  describe("new_session operation", function() {
    it("saves an image", function(done) {
      async.series(
        [
          function(callback) {
            sessionResponder.handler(
              {
                operation: 'new_session',
                data: {
                  timestamp: 123123,
                  observations: "AAAAUwAAAFYAAAFZAAACXA=="
                }
              }, null, callback);
          }
        ],
        function(err, result) {
          expect(err).toBeNull();
          var images = storageObj.savedObjects.filter(function(o) { return o.contentType == "image/png" });
          expect(images.length).toEqual(1);
          done();
        });
    });

    it("saves a new index.html", function(done) {
      async.series(
        [
          function(callback) {
            sessionResponder.handler(
              { operation: 'new_session',
                data: {
                  timestamp: 123123,
                  observations: "AAAAUwAAAFYAAAFZAAACXA=="
                }
              }, null, callback);
          }
        ],
        function(err, result) {
          expect(err).toBeNull();
          var htmls = storageObj.savedObjects.filter(function(o) { return o.contentType == "text/html" });
          expect(htmls.length).toEqual(2);
          done();
        });
    });

    it("saves a record", function(done) {
      async.waterfall([
        function(callback) {
          sessionResponder.handler(
            {
              operation: 'new_session',
              data: {
                timestamp: 123123,
                observations: new Buffer("AAAAUwAAAFYAAAFZAAACXA==", 'base64')
              }
            }, null, callback);
        },
        function(result, callback) {
          storage.getDDB().get({
            TableName: "HeartSessions",
            Key: {
              SessionShard: 0,
              SessionTimestamp: 123123 + sessionResponder.TIMESTAMP_OFFSET
            },
            ConsistentRead: true
          }, callback);
        },
        function(result, callback) {
          console.log("result is ", result);
          var item = result.Item;
          expect(item.SessionTimestamp).toEqual(123123 + sessionResponder.TIMESTAMP_OFFSET);
          expect(item.Observations.toString('base64')).toEqual('AAAAUwAAAFYAAAFZAAACXA==');
          expect(item.SessionDuration).toEqual(2);
          callback(null, result);
        }], done);
    });
  });

  describe("refresh operation", function() {
    function insertCallable(timestamp, version) {
      var observations = new Buffer('AAAAUwAAAFYAAAFZAAACXA==', 'base64');
      return function(callback) {
        var item = {
          "SessionShard": 0,
          "SessionTimestamp": timestamp + sessionResponder.TIMESTAMP_OFFSET,
          "Observations": observations,
          "Version": version
        };
        storage.getDDB().put({ TableName: "HeartSessions", Item: item }, callback);
      };
    }
    
    beforeEach(function(done) {
      var version = sessionResponder.VERSION;
      async.parallel([
        insertCallable(1, version - 1),
        insertCallable(2, version),
        insertCallable(3, version - 1)
      ], done);
    });

    it("refreshes html", function(done) {
      async.series(
        [
          function(callback) { sessionResponder.handler({ operation: 'refresh' }, null, callback); }
        ],
        function(err, result) {
          expect(err).toBeNull();
          var htmls = storageObj.savedObjects.filter(function(o) { return o.contentType == "text/html" });
          expect(htmls.length).toEqual(3);
          done();
        });
    });

    it("refreshes images", function(done) {
      async.series(
        [
          function(callback) { sessionResponder.handler({ operation: 'refresh' }, null, callback); }
        ],
        function(err, result) {
          expect(err).toBeNull();
          var images = storageObj.savedObjects.filter(function(o) { return o.contentType == "image/png" });
          expect(images.length).toEqual(2);
          done();
        });
    });

    it("updates records", function(done) {
      async.waterfall(
        [
          function(callback) { sessionResponder.handler({ operation: 'refresh' }, null, callback); },
          function(result, callback) {
            let params = {
              TableName: "HeartSessions",
              KeyConditionExpression: 'SessionShard = :zero and SessionTimestamp > :zero',
              ExpressionAttributeValues: {
                ':zero': 0
              },
              ProjectionExpression: 'SessionTimestamp,Version',
              ScanIndexForward: false,
              Select: 'SPECIFIC_ATTRIBUTES'
            };
            storage.getDDB().query(params, callback);
          }
        ],
        function(err, result) {
          var items = result.Items;
          for (var i = 0; i < items.length; i++) {
            expect(items[i].Version).toEqual(sessionResponder.VERSION);
          }
          done();
        });
    });
  });
});
