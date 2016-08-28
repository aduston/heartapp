var redis = require('redis');
client = redis.createClient();

exports.uniqueNumber = function(res) {
  client.incr("unique-number-for-testing", function(err, reply) {
    res(err, reply);
  });
}
