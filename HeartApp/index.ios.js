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
  NavigationExperimental,
  ScrollView,
  StyleSheet,
  Text,
  TouchableHighlight,
  View,
} = ReactNative;

const {
  CardStack: NavigationCardStack,
  Header: NavigationHeader,
} = NavigationExperimental;

import type { NavigationSceneRendererProps } from 'NavigationTypeDefinition';

class HeartApp extends React.Component {
  _renderOverlay: Function;
  _renderTitleComponent: Function;
  
  constructor(props) {
    super(props);
    this.state = {
      stack: {
        key: 'page0',
        index: 0,
        children: [
          { key: 'what', species: 'fuckthis' }
        ]
      }
    };
  }

  componentWillMount() {
    this._renderOverlay = this._renderOverlay.bind(this);
    this._renderTitleComponent = this._renderTitleComponent.bind(this);
    this._renderScene = this._renderScene.bind(this);
  }
  
  render() {
    return (
        <NavigationCardStack
         navigationState={this.state.stack}
         renderOverlay={this._renderOverlay}
         renderScene={this._renderScene}
        />
    );
  }

  _renderOverlay(props: NavigationSceneRendererProps): ReactElement<any>{
    console.log("rendering overlay");
    return (
        <NavigationHeader
          {...props}
          renderTitleComponent={this._renderTitleComponent}
          renderRightComponent={this._renderRightComponent}
        />
    );
  }

  _renderTitleComponent(props: NavigationSceneRendererProps): ReactElement<any> {
    return (
        <NavigationHeader.Title style={styles.title}>
        Hello
        </NavigationHeader.Title>
    );
  }

  _renderRightComponent(props): ReactElement<any> {
    return (
        <TouchableHighlight>
          <Text>New</Text>
        </TouchableHighlight>
    );
  }

  _renderScene(props) {
    return (
      <ScrollView/>
    );
  }
}

const styles = StyleSheet.create({
  title: {
    backgroundColor: 'yellow',
  },
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('HeartApp', () => HeartApp);
