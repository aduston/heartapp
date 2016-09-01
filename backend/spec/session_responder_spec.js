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

  it("saves an image", function(done) {
    async.series(
      [
        function(callback) {
          sessionResponder.handler(
            {
              timestamp: 123123,
              observations: "AAAAUwAAAFYAAAFZAAACXA=="
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

  it("saves a record", function(done) {
    async.series([
      function(callback) {
        sessionResponder.handler(
          {
            timestamp: 123123,
            observations: "AAAAUwAAAFYAAAFZAAACXA=="
          }, null, callback);
      },
      function(callback) {
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
      expect(err).toBeNull();
      var item = result[1].Item;
      expect(item.SessionTimestamp).toEqual(123123);
      expect(item.Observations.toString('base64')).toEqual('AAAAUwAAAFYAAAFZAAACXA==');
      done();
    });
  });
});
