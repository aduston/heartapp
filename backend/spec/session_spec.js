"use strict"

var utils = require('./helpers/utils')
var storage = require('../storage')
var AWS = require('aws-sdk')
var async = require('async')
var fs = require('fs');

describe("session", function() {
  var session = require('../session')
  
  it("Gives a correct object representation", function() {
    let observations = new Buffer("AAAAUwAAAFYAAAFZAAACXA==", 'base64');
    let obsArray = session.convertToObjArray(observations);
    expect(obsArray.length).toEqual(4);
    expect(obsArray[0].seconds).toEqual(0);
    expect(obsArray[0].heartRate).toEqual(83);
  });

  it("Does gets seconds right when halved", function() {
    let b64text = fs.readFileSync(__dirname + "/heartdata.txt", { encoding: 'ascii'});
    let buf = new Buffer(b64text, 'base64');
    let obs = session.convertToObjArray(buf);
    expect(obs.length).toEqual(9962);
    expect(obs[2142].halved).toEqual(true);
    expect(obs[2142].seconds).toEqual(2142);
  });

  it("Computes stats", function() {
    let b64text = fs.readFileSync(__dirname + "/heartdata.txt", { encoding: 'ascii'});
    let buf = new Buffer(b64text, 'base64');
    let obs = session.convertToObjArray(buf);
    let stats = session.computeStats(obs);
    expect(stats.numThreshold).toEqual(89);
    expect(stats.meanThreshold).toEqual(119);
    expect(stats.minThreshold).toEqual(89);
    expect(stats.maxThreshold).toEqual(135);
    expect(stats.duration).toEqual(9961);
  });
});
