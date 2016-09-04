"use strict"

var async = require('async');

var session = require('./session');
var storage = require('./storage');
var GraphDrawer = require('./graph_drawer');
var Canvas = require('canvas');
var StringBuilder = require('stringbuilder');
var moment = require('moment');

let VERSION = 2;
let IMAGE_WIDTH = 1200;
let IMAGE_HEIGHT = 300;
// iOS reports timestamp in seconds since 1/1/2001.
let TIMESTAMP_OFFSET = 978307200;

exports.TIMESTAMP_OFFSET = TIMESTAMP_OFFSET;
exports.VERSION = VERSION;

exports.handler = function(event, context, callback) {
  console.log('Received event:', JSON.stringify(event, null, 2));
  if (event['operation'] == 'new_session') {
    saveNewSession(event['data'], callback)
  } else if (event['operation'] == 'refresh') {
    refreshEverything(updateItemImageAndHTML, callback);
  }
};

function refreshEverything(itemFn, callback) {
  async.series(
    [
      function(callback) { refreshItems(itemFn, callback); },
      function(callback) { updateIndexHTML(null, callback); }
    ],
    function(err, result) {
      if (err == null) {
        callback(null, { "success": true })
      } else {
        callback(err, null)
      }
    }
  )
}

function refreshItems(itemFn, callback) {
  async.waterfall(
    [
      runQuery,
      function(sessions, callback) {
        var callables = [];
        for (var i = 0; i < sessions.length; i++) {
          if (sessions[i].Version < VERSION) {
            callables.push(function(session) {
              return function(callback) { refreshItem(session.SessionTimestamp, itemFn, callback); };
            }(sessions[i]));
          }
        }
        async.parallel(callables, callback);
      }
    ], callback);
}

function refreshItem(sessionTimestamp, itemFn, callback) {
  async.waterfall([
    function(callback) {
      fetchFullItem(sessionTimestamp, callback);
    },
    itemFn,
    function(result, callback) {
      updateItemVersion(sessionTimestamp, callback);
    }
  ], callback);
}

function updateItemImageAndHTML(fullItem, callback) {
  async.parallel([
    function(callback) { saveImage(fullItem.SessionTimestamp, fullItem.Observations, callback); },
    function(callback) { updateSessionHTML(fullItem, callback); }
  ], callback);
}

function fetchFullItem(timestamp, callback) {
  storage.getDDB().get({
    TableName: "HeartSessions",
    Key: {
      SessionShard: 0,
      SessionTimestamp: timestamp
    }
  }, function(err, result) {
    if (err != null) {
      callback(err, result);
    } else {
      callback(null, result.Item);
    }
  });
}

function saveNewSession(data, callback) {
  let timestamp = data['timestamp'] + TIMESTAMP_OFFSET;
  let observations = new Buffer(data['observations'], 'base64');
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
}

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
  let fileName = timestamp + ".json";
  var json = JSON.stringify(session.convertToObjArray(observations).map(
    function(obs) {
      return [obs.seconds, (obs.halved ? 1 : 0), obs.heartRate];
    }));
  storage.saveObject(fileName, json, "text/plain", callback);
}

function updateHTML(item, callback) {
  async.parallel([
    function(callback) { updateIndexHTML(item, callback); },
    function(callback) { updateSessionHTML(item, callback); }
  ], callback);
}

function updateSessionHTML(item, callback) {
  var formattedTimestamp = moment.unix(item.SessionTimestamp).format('MMMM Do YYYY, h:mm:ss a');
  var title = "Adam&apos;s Heart: " + formattedTimestamp;
  var html = new StringBuilder();
  html.append('<!doctype html><html lang="en">' +
              '<head><meta charset="utf-8"><title>' + title + '</title></head>' +
              '<body>');
  writeResultToHTML(html, item);
  html.append("<script>var timestamp = " + item.SessionTimestamp + ";</script></body></html>");
  async.waterfall([
    function(callback) {
      html.build(callback);
    },
    function(result, callback) {
      storage.saveObject("" + item.SessionTimestamp, result, "text/html", callback);
    },
    function(result, callback) {
      storage.invalidatePath("/" + item.SessionTimestamp, callback);
    }
  ], callback);
}

function updateIndexHTML(item, callback) {
  async.waterfall([
    function(callback) {
      runQuery(callback);
    },
    function(results, callback) {
      if (item != null && !results.find(function(i) { return i.SessionTimestamp == item.SessionTimestamp; })) {
        results.push(item);
      }
      results.sort(function(a, b) { return a.SessionTimestamp > b.SessionTimestamp ? -1 : 1 });
      updateHTMLWithResults(results, callback);
    }
  ], callback);
}

function updateHTMLWithResults(results, callback) {
  var resultsJson = JSON.stringify(results.map(function(result) {
    return result.SessionTimestamp + "." + result.Version;
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
  html.append('<div id="session-' + result.SessionTimestamp  + '"><img src="' +
              result.SessionTimestamp + '.' +
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

function updateItemVersion(timestamp, callback) {
  let params = {
    TableName: "HeartSessions",
    Key: { SessionShard: 0, SessionTimestamp: timestamp },
    UpdateExpression: "set Version = :version",
    ExpressionAttributeValues: {
      ':version': VERSION
    }
  };
  storage.getDDB().update(params, callback);
}
