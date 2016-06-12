'use strict'

import React from 'react';
import { requireNativeComponent } from 'react-native';

class ChartView extends React.Component {
  render() {
    return <RCTChart {...this.props} />;
  }
}

ChartView.propTypes = {
  data: React.PropTypes.array.isRequired
};

var RCTChart = requireNativeComponent('RCTChart', ChartView);

module.exports = ChartView;
