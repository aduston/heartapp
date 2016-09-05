'use strict'

// uses https://github.com/Automattic/node-canvas

var AWS = require('aws-sdk');
var Canvas = require('canvas');
var fs = require('fs');
var async = require('async');
var storage = require('./storage');
var session = require('./session');

var Image = Canvas.Image;
var GraphDrawer = require('./graph_drawer');

let b64text = fs.readFileSync("/Users/aduston/dev/heartapp/backend/spec/heartdata.txt", { encoding: 'ascii'});
let buf = new Buffer(b64text, 'base64');
var obs = session.convertToObjArray(buf);

// obs = obs.slice(1900, 2900);

let canvas = new Canvas(980, 220);
var graphDrawer = new GraphDrawer(980, 220, obs);

graphDrawer.draw(canvas, 0, obs.length)
canvas.toBuffer(function(err, buf) {
  if (err == null) {
    fs.writeFile("/Users/aduston/hr.png", buf);
  }
  console.log("done", err);
});
