/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */
'use strict';

const React = require('react');
const ReactNative = require('react-native');

const {
  AppRegistry,
  Navigator,
  ScrollView,
  StyleSheet,
  Text,
  TouchableHighlight,
  View,
} = ReactNative;

var ListingPage = require('./ListingPage');
var RecordScreen = require('./RecordScreen');

class HeartApp extends React.Component {
  constructor(props) {
    super(props);
  }
  
  render() {
    return (
        <Navigator
          initialRoute={{message: 'yeah',}}
          renderScene={this._renderScene.bind(this)}
          configureScene={this._configureScene.bind(this)}
        />
    );
  }

  _configureScene(route) {
    return Navigator.SceneConfigs.FloatFromBottom;
  }

  _recordPressed(nav) {
    nav.push({ id: 'record', })
  }

  _renderScene(route, nav) {
    switch (route.id) {
    case 'record':
      return (
          <RecordScreen navigator={nav}/>
      );
    default:
      return (
          <View style={styles.container}>
          <Text>Hello</Text>
          <TouchableHighlight onPress={this._recordPressed.bind(this, nav)}>
          <View><Text>Record</Text></View>
          </TouchableHighlight>
          </View>
      );
    }
  }
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'yellow',
    marginTop: 20,
  },
});

AppRegistry.registerComponent('HeartApp', () => HeartApp);
