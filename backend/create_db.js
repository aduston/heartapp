"use strict"

var schema = require("./schema")

schema.createAll(schema.realddb, function(err, result) {
  console.log(err, result);
});
