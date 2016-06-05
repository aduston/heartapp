'use strict';

var React = require('react');
var ReactNative = require('react-native');

const {
  StyleSheet,
  Text,
  TouchableHighlight,
  View
} = ReactNative;

class HeartRateDisplay extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      count: 0,
      hr: null
    };
    this._count = 0;
    this._peripheral = props.peripheral;
    this._characteristic = null;
    this._dataReceived = this._dataReceived.bind(this);
  }

  componentDidMount() {
    this._peripheral.connect(this._connected.bind(this));
  }

  _connected(error) {
    console.log("_connected", error);
    this._peripheral.once('disconnect', this._disconnected.bind(this));
    this._peripheral.discoverSomeServicesAndCharacteristics(
      ["180D"], ["2A37"], this._characteristicDiscovered.bind(this));
  }

  _disconnected() {
    console.log("_disconnected");
    if (this._characteristic) {
      this._characteristic.removeListener('data', this._dataReceived);
    }
    this._peripheral.connect(this._connected.bind(this));
  }

  _characteristicDiscovered(error, services, characteristics) {
    console.log("discovered characteristics", services[0].uuid, characteristics[0].uuid);
    this._characteristic = characteristics[0];
    this._characteristic.on("data", this._dataReceived);
    this._characteristic.notify(true);
  }

  _dataReceived(data, notification) {
    this._count++;
    var parsedData = this._parseHR(data);
    this.setState({
      count: this._count,
      hr: parsedData.hr
    });
  }

  _parseHR(bytes) {
    if (bytes.length == 0) {
      return 0;
    }
    // https://www.bluetooth.org/docman/handlers/downloaddoc.ashx?doc_id=239866
    var flags = bytes[0];
    var hrFormat = flags & 0x1;
    var contactStatus = (flags & 0x2) >> 1;
    var contactSupport = (flags & 0x4) >> 2;
    var energyExpended = (flags & 0x8) >> 3;
    var rrInterval = (flags & 0x10) >> 4;

    var offset = 1;
    var hrBytes = bytes.buffer.slice(offset, offset + 1 + hrFormat);
    var hr = hrFormat == 1 ? new Uint16Array(hrBytes)[0] : new Uint8Array(hrBytes)[0];
    offset += hrFormat + 1;

    // TODO: energy expended and rr
    
    return {
      hr: hr
    }
  }

  render() {
    return (
        <View>
        <Text>{this.state.count}</Text>
        <Text>{this.state.hr}</Text>
        </View>
    );
  }
}

module.exports = HeartRateDisplay;
