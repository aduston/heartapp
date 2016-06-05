'use strict';

var React = require('react');
var ReactNative = require('react-native');
var noble = require('react-native-ble');

const {
  StyleSheet,
  Text,
  TouchableHighlight,
  View,
} = ReactNative;

const MONITOR_DISCOVERED = 0,
      MONITOR_CONNECTING = 1,
      MONITOR_CONNECTED = 2;

class RecordScreen extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      bluetoothOn: false,
      monitorName: null,
      monitorState: null
    };
  }

  _dismissTouched() {
    this.props.navigator.pop();
  }

  componentDidMount() {
    if (noble.state == 'poweredOn') {
      this._bluetoothStateChanged(true);
    }
    noble.on('stateChange', this._onStateChange.bind(this));
    noble.on('discover', this._onPeripheralFound.bind(this));
  }

  _onStateChange(state) {
    this._bluetoothStateChanged(state == 'poweredOn');
  }

  _bluetoothStateChanged(on) {
    if (on) {
      this.setState({ bluetoothOn: true });
      noble.startScanning(['180D']);
    } else {
      this.setState({ bluetoothOn: false });
      noble.stopScanning();
    }
  }

  _onPeripheralFound(peripheral) {
    var monitorName = peripheral.advertisement.localName;
    if (!monitorName && peripheral.advertisement.manufacturerData) {
      monitorName = peripheral.advertisement.manufacturerData.toString('hex');
    }
    this.setState({
      monitorName: monitorName
    });
  }

  _connectHeartRate(peripheral) {
    function parseHR (bytes) {
      if (bytes.length == 0) {
        return 0;
      }
      // see
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

    function print(data, notification) {
      var parsedData = parseHR(data);
      
    }

    var characteristic;

    function notify(error, services, characteristics) {
      console.log("discovered characteristics", services[0].uuid, characteristics[0].uuid);
      self.characteristic = characteristics[0];
      self.characteristic.notify(true);
      self.characteristic.on("data", print);
    };

    function disconnected() {
      console.log("disconnected");
      self.characteristic.removeListener('data', print);
      self._connectHeartRate(peripheral);
      self.setState({
        heartRate:0
      });
    };

    function discover(error){
      peripheral.once('disconnect', disconnected);
      console.log("connect", error);
      peripheral.discoverSomeServicesAndCharacteristics(["180d"], ["2a37"], notify);
    }
    peripheral.connect(discover);
  }
});
  
  render() {
    var bluetoothState = null;
    var connectedMonitor = null;
    if (!this.state.bluetoothOn) {
      bluetoothState = (
          <View>
          <Text>BLUETOOTH OFF</Text>
          </View>
      );
    } else {
      if (this.state.monitorName) {
        connectedMonitor = (
            <View>
            <Text>Connected to {this.state.monitorName}</Text>
            </View>
        );
      }
    }
    return (
        <View>
          <Text>Record screen</Text>
            <TouchableHighlight
               onPress={this._dismissTouched.bind(this)}>
             <View><Text>Cancel</Text></View>
            </TouchableHighlight>
        {bluetoothState}
      {connectedMonitor}
        </View>
    );
  }
}

module.exports = RecordScreen;
