"use strict"

var AWS = require('aws-sdk');

var localddb = new AWS.DynamoDB({
  apiVersion: '2012-08-10',
  endpoint: 'http://localhost:8000',
  region: 'us-east-1'
});

var realddb = new AWS.DynamoDB({
  apiVersion: '2012-08-10',
  region: 'us-east-1'
});

class TableDef {
  constructor(tableName, keys, throughput) {
    this.tableName = tableName
    this.keys = keys
    this.throughput = throughput
  }
  toCreateParams() {
    var keySchema = [{ AttributeName: this.keys[0][0], KeyType: "HASH" }]
    var attDefs = [{ AttributeName: this.keys[0][0], AttributeType: this.keys[0][1] }]
    if (this.keys.length > 1) {
      keySchema.push({ AttributeName: this.keys[1][0], KeyType: "RANGE" })
      attDefs.push({ AttributeName: this.keys[1][0], AttributeType: this.keys[1][1] })
    }
    return {
      TableName: this.tableName,
      KeySchema: keySchema,
      ProvisionedThroughput: {
        ReadCapacityUnits: this.throughput[0],
        WriteCapacityUnits: this.throughput[1]
      },
      AttributeDefinitions: attDefs
    }
  }
  create(ddb) {
    ddb.createTable(this.toCreateParams(), function(err, data) {
      if (err) console.log(err, err.stack);
      else console.log(data);
    });
  }
  delete(ddb) {
    ddb.deleteTable({ TableName: this.tableName }, function(err, data) {
      if (err) console.log(err, err.stack);
      else console.log(data);
    });
  }
}

function tableDefs() {
  return [
    new TableDef("HeartSessions", [["SessionShard", "N"], ["SessionTimestamp", "N"]], [5, 5])
  ]
}

function createAll(ddb) {
  for (var tableDef of tableDefs()) {
    tableDef.create(ddb)
  }
}

function deleteAll(ddb) {
  for (var tableDef of tableDefs()) {
    tableDef.delete(ddb)
  }
}

deleteAll(localddb)
createAll(localddb)
