'use strict'

var React = require('react');
var ReactNative = require('react-native');

const {
  ListView,
  StyleSheet,
  Text,
  View,
} = ReactNative;

class ListingPage extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
        <View>
          <Text>Listing page</Text>
        </View>
    );
  }
}

module.exports = ListingPage;
