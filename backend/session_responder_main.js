"use strict"

function before(done) {
  AWS.config.update({ region: 'us-east-1c' });
  AWS.config.dynamodb = { endpoint: 'http://localhost:8000' };
  async.parallel([
    function(callback) {
      schema.deleteAndCreateLocal(callback);
    },
    function(callback) {
      storage.initForTesting(function(err, result) {
        storageObj = result;
        callback(err, result);
      });
    }
  ], done);
}
