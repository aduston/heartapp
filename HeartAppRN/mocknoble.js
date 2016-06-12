'use strict';

exports.state = 'poweredOn';

exports.on = function(event, callback) {
  if (event == 'discover') {
    setTimeout(function() { callback(new MockPeripheral()); }, 100);
  }
}

exports.startScanning = function(x) {};
exports.stopScanning = function() {};

class MockPeripheral {
  constructor() {
    this.advertisement = {
      localName: 'polar strap'
    };
  }

  connect(callback) {
    setTimeout(function() { callback(null); }, 100);
  }

  once(x, y) {
    
  }

  discoverSomeServicesAndCharacteristics(s, c, callback) {
    setTimeout(
      function() {
        callback(
          null,
          [{ uuid: 'service_uuid' }],
          [new MockCharacteristic()]);
      },
      100);
  }
}

class MockCharacteristic {
  constructor() {
    this.uuid = 'characteristic_uuid';
    this._intervalId = setInterval(
      this._sendNotification.bind(this),
      1000);
    this._hr = 10;
  }
  
  on(event, callback) {
    if (event == 'data') {
      this._notificationCallback = callback;
    }
  }

  notify(x) {
  }

  _sendNotification() {
    if (!this._notificationCallback) {
      return;
    }
    var flags = 0x1;
    this._hr += 3;
    this._hr %= 80;

    var arr = [0x1, 0x0, this._hr];
    var buf = new ArrayBuffer(3);
    var view = new Uint8Array(buf);
    view[0] = 0x1;
    view[1] = this._hr + 50 + Math.random() * 40;
    view[2] = 0;
    arr.buffer = buf;
    this._notificationCallback(arr, null);
  }
}
