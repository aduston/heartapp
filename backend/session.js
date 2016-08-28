"use strict"

class Session {
  constructor(timestamp, observations) {
    this.timestamp = timestamp;
    this.observations = observations;
  }

  toObj() {
    var objObs = [];
    let len = this.observations.length;
    for (var offset = 0; offset < len; offset += 4) {
      let obs = this.observations.readInt32BE(offset);
      objObs.push({
        seconds: (obs >> 8) & ~(1 << 23),
        halved: (obs >> 31) != 0,
        heartRate: obs & 0xFF
      });
    }
    return objObs;
  }
}

module.exports = Session;
