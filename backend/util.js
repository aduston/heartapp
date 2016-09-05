'use strict'

exports.formatTime = function(seconds) {
  function pad(num) {
    var num = num + '';
    return num.length == 1 ? ('0' + num) : num;
  }
  if (seconds < 60) {
    return '0:' + pad(seconds);
  } else if (seconds < 3600) {
    return Math.floor(seconds / 60) + ':' + pad(seconds % 60, 2);
  } else {
    return Math.floor(seconds / 3600) + ':' +
      pad(Math.floor((seconds % 3600) / 60), 2) + ':' +
      pad(seconds % 60, 2);
  }
}
