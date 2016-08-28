'use strict'

// uses https://github.com/Automattic/node-canvas

var Canvas = require('canvas');
var fs = require('fs');

var Image = Canvas.Image;


var drawer = require('./graph_drawer');

var numMinutes = 0.1;

var obs = [];

obs[0] = {
  seconds: 0,
  halved: false,
  heartRate: 100
};

for (var i = 1; i < 60 * numMinutes; i++) {
  var hr = Math.floor(obs[i - 1].heartRate + (Math.random() - 0.40) * 80);
  hr = Math.max(40, Math.min(170, hr));
  obs[i] = {
    seconds: i,
    halved: false,
    heartRate: hr
  };
}

let canvas = new Canvas(1200, 400);
var imageDrawer = new drawer.ImageDrawer(1200, 400, obs);

imageDrawer.draw(canvas, 0.3, 60 * numMinutes - 1)
canvas.toBuffer(function(err, buf) {
  if (err == null) {
    fs.writeFile("/Users/aduston/hr.png", buf);
  }
  console.log("done", err);
});
