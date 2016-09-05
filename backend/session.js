"use strict"

exports.convertToObjArray = function(observations) {
  var objArray = [];
  let len = observations.length;
  for (var offset = 0; offset < len; offset += 4) {
    let obs = observations.readUInt32BE(offset);
    objArray.push({
      seconds: (obs >>> 8) & ~(1 << 23),
      halved: (obs >> 31) != 0,
      heartRate: obs & 0xFF
    });
  }
  return objArray;
};

exports.computeStats = function(obs) {
  var sum = 0.0;
  var sumSquares = 0.0;
  var min = 300;
  var max = 0;
  var count = 0;

  var lastHalved = false;
  var lastHR = 0;

  for (var i = 0; i < obs.length; i++) {
    if (obs[i].halved && !lastHalved && lastHR != 0) {
      sum += lastHR;
      sumSquares += (lastHR * lastHR);
      if (lastHR < min) min = lastHR;
      if (lastHR > max) max = lastHR;
      count += 1;
    }
    lastHalved = obs[i].halved;
    lastHR = obs[i].heartRate;
  }

  var stats = {
    duration: obs[obs.length - 1].seconds - obs[0].seconds,
    numThreshold: count
  };
  if (count > 0) {
    let mean = sum / count;
    let stdDev = Math.sqrt(sumSquares / count - mean * mean);
    let reportedMin = Math.max(min, mean - 3 * stdDev);
    let reportedMax = Math.min(max, mean + 3 * stdDev);
    stats.meanThreshold = Math.round(mean);
    stats.minThreshold = Math.round(reportedMin);
    stats.maxThreshold = Math.round(reportedMax);
  }
  return stats;
};
