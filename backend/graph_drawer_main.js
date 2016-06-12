'use strict'

var drawer = require('./graph_drawer');

var hr = new Uint8Array(60 * 8);

for (var i = 0; i < 60 * 8; i++) {
  hr[i] = 70 + Math.random() * 60;
}

drawer.draw(1200, 400, hr, null, "/Users/aduston/hr.png", function(err) { console.log("done", err); });
