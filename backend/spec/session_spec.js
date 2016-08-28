"use strict"

var utils = require('./helpers/utils')
var storage = require('../storage')
var AWS = require('aws-sdk')
var async = require('async')

describe("session", function() {
  var Session = require('../session')
  
  it("Gives a correct object representation", function() {
    let observations = new Buffer("AAAAUwAAAFYAAAFZAAACXA==", 'base64');
    let s = new Session(234, observations);
    let obsObj = s.toObj();
    expect(obsObj.length).toEqual(4);
    expect(obsObj[0].seconds).toEqual(0);
    expect(obsObj[0].heartRate).toEqual(83);
  });
});
