'use strict'

var drawer = require('./graph_drawer');

var hr = new Uint8Array(60 * 45);

hr[0] = 100;

for (var i = 1; i < 60 * 45; i++) {
  hr[i] = Math.floor(hr[i - 1] + (Math.random() - 0.40) * 5);
  hr[i] = Math.min(180, Math.max(60, hr[i]));
}

drawer.draw(1200, 400, hr, null, "/Users/aduston/hr.png", function(err) { console.log("done", err); });
