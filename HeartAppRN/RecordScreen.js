'use strict';

var React = require('react');
var ReactNative = require('react-native');
 
// var noble = require('react-native-ble');
var noble = require('./mocknoble');

const {
  StyleSheet,
  Text,
  TouchableHighlight,
  View,
} = ReactNative;

var HeartRateDisplay = require('./HeartRateDisplay');

class RecordScreen extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      bluetoothOn: false,
      monitorName: null,
      peripheral: null
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
      monitorName: monitorName,
      peripheral: peripheral
    });
  }
  
  render() {
    var bluetoothState = null;
    var connectedMonitor = null;
    var rateDisplay = null;
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
        rateDisplay = (
            <HeartRateDisplay peripheral={this.state.peripheral}/>
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
        {rateDisplay}
        </View>
    );
  }
}

module.exports = RecordScreen;
