'use strict';

var React = require('react');
var ReactNative = require('react-native');

var ChartView = require('./ChartView');

const {
  Dimensions,
  ListView,
  StyleSheet,
  Text,
  View,
} = ReactNative;

class HeartRateDisplay extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      currentObservation: -1
    };
    // don't keep this screen open for more than 24 hours
    // and you'll be fine.
    this._observations = new Uint8Array(24 * 60 * 60);
    this._minuteIndexes = new Uint32Array(24 * 60);
    this._currentMinute = -1;
    this._startTime = null;
    
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
    var currentObservation = this.state.currentObservation + 1;
    if (currentObservation == 0) {
      this._startTime = new Date().getTime();
      this._currentMinute = 0;
      this._minuteIndexes[0] = 0;
    } else {
      var elapsedTime = new Date().getTime() - this._startTime;
      if (elapsedTime % 60000 < 1800) {
        // we might be at a new minute.
        var curMinute = Math.floor(elapsedTime / 60000);
        if (curMinute > this._currentMinute) {
          // we have not yet recorded the starting observation index
          // for this minute.
          this._currentMinute = curMinute;
          this._minuteIndexes[curMinute] = currentObservation;
        }
      }
    }
    var parsedData = this._parseHR(data);
    this._observations[currentObservation] = parsedData.hr;

    this.setState({
      currentObservation: currentObservation
    });
  }

  _formatCurrentTime() {
    var elapsedTime = new Date().getTime() - this._startTime;
    var seconds = Math.floor(elapsedTime / 1000);
    var hours = Math.floor(seconds / 3600);
    var minutes = Math.floor(seconds / 60) % 60;
    seconds = Math.floor(seconds % 60);
    var secondsString = seconds < 10 ? (":0" + seconds) : (":" + seconds);
    if (hours == 0) {
      return minutes + secondsString;
    } else {
      var minutesString = minutes < 10 ? (":0" + minutes) : (":" + minutes);
      return hours + minutesString + secondsString;
    }
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
      hr: hr,
      contactStatus: contactStatus,
      contactSupport: contactSupport,
    }
  }

  render() {
    if (this.state.currentObservation < 0) {
      return (
          <View>
            <Text>Waiting for data...</Text>
          </View>
      );
    } else {
      var data = [];
      var startIndex = Math.max(0, this.state.currentObservation - 59);
      for (var index = startIndex; index <= this.state.currentObservation; index++) {
        data.push({
          hr: this._observations[index],
        });
      }
      return (
          <View>
          <View style={styles.numDisplays}>
          <View style={styles.numDisplay}>
              <Text style={styles.hrDisplay}>{this._observations[this.state.currentObservation]}</Text>
          </View>
          <View style={styles.numDisplay}>
          <Text style={styles.timeDisplay}>{this._formatCurrentTime()}</Text>
          </View>
            </View>
            <ChartView data={data} style={styles.chartView} />
          </View>
      );
    }
  }
}

var styles = StyleSheet.create({
  chartView: {
    marginLeft: 5,
    marginTop: 10,
    width: Dimensions.get('window').width - 10,
    height: 300
  },
  numDisplays: {
    flexDirection: "row"
  },
  numDisplay: {
    flex: 1
  },
  hrDisplay: {
    fontSize: 60,
    textAlign: 'center',
  },
  timeDisplay: {
    fontSize: 60,
    textAlign: 'right',
  }
});

module.exports = HeartRateDisplay;
