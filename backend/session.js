"use strict"

exports.convertToObjArray = function(observations) {
  var objArray = [];
  let len = observations.length;
  for (var offset = 0; offset < len; offset += 4) {
    let obs = observations.readInt32BE(offset);
    objArray.push({
      seconds: (obs >> 8) & ~(1 << 23),
      halved: (obs >> 31) != 0,
      heartRate: obs & 0xFF
    });
  }
  return objArray;
}
