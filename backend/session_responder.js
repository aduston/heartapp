"use strict"

var async = require('async');

var session = require('./session');
var storage = require('./storage');
var GraphDrawer = require('./graph_drawer');
var Canvas = require('canvas');
var StringBuilder = require('stringbuilder');

let VERSION = 0;
let IMAGE_WIDTH = 1200;
let IMAGE_HEIGHT = 300;

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
    "SessionShard": 0,
    "SessionTimestamp": timestamp,
    "Observations": observations,
    "Version": VERSION
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
  let fileName = timestamp + "." + VERSION + ".png";
  var objArray = session.convertToObjArray(observations);
  var graphDrawer = new GraphDrawer(IMAGE_WIDTH, IMAGE_HEIGHT, objArray);
  let canvas = new Canvas(IMAGE_WIDTH, IMAGE_HEIGHT);
  graphDrawer.draw(canvas, 0, objArray.length);
  async.waterfall([
    function(callback) {
      canvas.toBuffer(callback);
    },
    function(buffer, callback) {
      storage.saveObject(fileName, buffer, "image/png", callback);
    }
  ], callback);
}

function saveDataToJSON(timestamp, observations, callback) {
  let fileName = timestamp + "." + VERSION + ".json";
  var json = JSON.stringify(session.convertToObjArray(observations).map(
    function(obs) {
      return [obs.seconds, (obs.halved ? 1 : 0), obs.heartRate];
    }));
  storage.saveObject(fileName, json, "text/plain", callback);
}

function updateHTML(item, callback) {
  async.waterfall([
    function(callback) {
      runQuery(callback);
    },
    function(results, callback) {
      if (!results.find(function(i) { return i.SessionTimestamp == item.SessionTimestamp; })) {
        results.push(item);
      }
      results.sort(function(a, b) { return a.SessionTimestamp > b.SessionTimestamp ? -1 : 1 });
      updateHTMLWithResults(results, callback);
    }
  ], callback);
}

function updateHTMLWithResults(results, callback) {
  var resultsJson = JSON.stringify(results.map(function(result) {
    return result["SessionTimestamp"] + "." + result["Version"];
  }));
  var html = new StringBuilder();
  html.append('<!doctype html><html lang="en">' +
              '<head><meta charset="utf-8"><title>Adam&apos;s Heart</title></head>' +
              '<body>');
  var numResultsToWrite = Math.min(10, results.length);
  for (var i = 0; i < numResultsToWrite; i++) {
    writeResultToHTML(html, results[i]);
  }
  html.append("<script>var timestamps = ");
  html.append(resultsJson);
  html.append(';</script></body></html>');
  async.waterfall([
    function(callback) {
      html.build(callback);
    },
    function(result, callback) {
      storage.saveObject("index.html", result, "text/html", callback);
    },
    function(result, callback) {
      storage.invalidatePath('/index.html', callback);
    }
  ], callback);
}

function writeResultToHTML(html, result) {
  html.append('<div><img src="' + result['SessionTimestamp'] + '.' +
              result['Version'] + '.png" width="' + IMAGE_WIDTH +
              '" height="' + IMAGE_HEIGHT + '"></img></div>');
}

function runQuery(callback) {
  let allResults = [];
  let query = function(lastEvaluatedKey) {
    runRawQuery(lastEvaluatedKey, function(err, results) {
      if (err != null) {
        callback(err, null);
        return;
      } else {
        if (results.Items.length > 0) {
          allResults.push.apply(allResults, results.Items);
        }
        if (results.lastEvaluatedKey) {
          query(results.lastEvaluatedKey);
        } else {
          callback(null, allResults);
        }
      }
    });
  };
  query();
}

function runRawQuery(lastEvaluatedKey, callback) {
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
  if (lastEvaluatedKey != null) {
    params.ExclusiveStartKey = lastEvaluatedKey;
  }
  storage.getDDB().query(params, callback);
};
