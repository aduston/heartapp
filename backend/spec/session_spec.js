"use strict"

var utils = require('./helpers/utils')
var storage = require('../storage')
var AWS = require('aws-sdk')
var async = require('async')

describe("session", function() {
  var session = require('../session')
  
  it("Gives a correct object representation", function() {
    let observations = new Buffer("AAAAUwAAAFYAAAFZAAACXA==", 'base64');
    let obsArray = session.convertToObjArray(observations);
    expect(obsArray.length).toEqual(4);
    expect(obsArray[0].seconds).toEqual(0);
    expect(obsArray[0].heartRate).toEqual(83);
  });
});
