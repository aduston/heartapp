'use strict';

var React = require('react');
var ReactNative = require('react-native');

const {
  StyleSheet,
  Text,
  TouchableHighlight,
  View,
} = ReactNative;

class RecordScreen extends React.Component {
  constructor(props) {
    super(props);
  }

  _dismissTouched() {
    this.props.navigator.pop();
  }
  
  render() {
    return (
        <View>
          <Text>Record screen</Text>
            <TouchableHighlight
               onPress={this._dismissTouched.bind(this)}>
             <View><Text>Cancel</Text></View>
            </TouchableHighlight>
        </View>
    );
  }
}

module.exports = RecordScreen;
