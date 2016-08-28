"use strict"

var storage = require('./storage');
var async = require('async');

let version = 0;

exports.handler = function(event, context, callback) {
  console.log('Received event:', JSON.stringify(event, null, 2));
  let timestamp = event['timestamp'];
  let observations = new Buffer(event['observations'], 'base64');
  let item = makeItem(timestamp, observations);
  async.parallel(
    [
      function(callback) {
        saveImage(timestamp, observations, callback);
      },
      function(callback) {
        saveDataToJSON(timestamp, observations, callback);
      },
      function(callback) {
        updateHTML(item, callback);
      },
      function(callback) {
        saveRecord(item, callback);
      }
    ],
    function(err, result) {
      if (err == null) {
        callback(null, { "success": true });
      } else {
        callback(err, null);
      }
    }
  );
};

function makeItem(timestamp, observations) {
  return {
    "Timestamp": timestamp,
    "Observations": observations,
    "Version": version
  };
}

function saveRecord(item, callback) {
  storage.getDDB().put(
    {
      TableName: "HeartSessions",
      Item: item,
    }, callback);
}

function saveImage(timestamp, observations, callback) {
  
}

function saveDataToJSON(timestamp, observations, callback) {
  
}

function updateHTML(item, callback) {
  
}
