'use strict'

// uses https://github.com/Automattic/node-canvas

var AWS = require('aws-sdk');
var Canvas = require('canvas');
var fs = require('fs');
var async = require('async');
var storage = require('./storage');

var Image = Canvas.Image;
var GraphDrawer = require('./graph_drawer');

var service = new AWS.DynamoDB({
  apiVersion: '2012-08-10',
  region: 'us-east-1'
});
var ddb = new AWS.DynamoDB.DocumentClient({ service: service });

async.waterfall([
  function(callback) {
    ddb.get({
      TableName: "HeartSessions",
      Key: {
        SessionShard: 0,
        SessionTimestamp: 1472845130
      }
    }, callback);
  },
  function(result, callback) {
    var item = result.Item;
    console.log(item.Observations);
    var b64string = item.Observations.toString('base64');
    var newBuf = new Buffer(b64string, 'base64');
    console.log(newBuf);
    fs.writeFile("/Users/aduston/dev/heartapp/backend/spec/heartdata.txt", b64string);
    let b64text = fs.readFileSync("/Users/aduston/dev/heartapp/backend/spec/heartdata.txt", { encoding: 'ascii'});
    console.log(b64text.substring(0, 20));
    var buf = new Buffer(b64text, 'base64');
    console.log(buf);
  }], function(err, result) {
    console.log(err, result);
  });
