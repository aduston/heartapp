'use strict'

var gm = require('gm').subClass({ imageMagick: true });

class ImageDrawer {
  constructor(width, height, observations, minuteIndexes) {
    this._img = gm(width, height, '#ffffff');
    this._width = width;
    this._height = height;
    this._observations = observations;
    this._minuteIndexes = minuteIndexes;

    this._topMargin = 10;
    this._bottomMargin = 40;
    this._leftMargin = 30;
    this._rightMargin = 30;
    this._minBarHeight = 10;

    this._minValue = Math.min.apply(Math, this._observations);
    this._maxValue = Math.max.apply(Math, this._observations);
    if (this._maxValue % 10 != 0) {
      this._maxValue += (10 - (this._maxValue % 10));
    }
    if (this._minValue % 10 != 0) {
      this._minValue -= (this._minValue % 10);
    }
    this._barWidth =
      (this._width - this._leftMargin - this._rightMargin) / this._observations.length;
    var maxBarHeight = this._height - this._topMargin - this._bottomMargin - this._minBarHeight; 
    this._beatHeight = maxBarHeight / (this._maxValue - this._minValue);
  }

  draw(output, done) {
    this._drawValues();
    this._drawHorizontalLines();
    this._drawTimes();
    this._img.write(output, done);
  }

  _drawValues() {
    if (this._barWidth > 1.0) {
      this._drawWideValues();
    } else {
      var img = this._img.stroke('#00f', 0.5);
      var totalWidth = this._width - this._leftMargin - this._rightMargin
      for (var i = 0; i < totalWidth; i++) {
        var minMax = this._minAndMaxAt(i, totalWidth);
        var min = minMax[0];
        var max = minMax[1];
        var x = this._leftMargin + i;
        var y0 = this._height - (this._bottomMargin + this._minBarHeight +
                                 (max - this._minValue) * this._beatHeight);
        img = img.drawLine(x, y0, x, y0 + (max - min) * this._beatHeight);
      }
    }
  }

  _minAndMaxAt(partition, numPartitions) {
    var minIndex = Math.floor((partition / numPartitions) * this._observations.length);
    var maxIndex = Math.ceil(((partition + 1) / numPartitions) * this._observations.length);
    var min = 999;
    var max = 0;
    for (var i = minIndex; i < maxIndex; i++) {
      if (this._observations[i] < min) {
        min = this._observations[i];
      }
      if (this._observations[i] > max) {
        max = this._observations[i];
      }
    }
    return [min, max];
  }

  _drawWideValues() {
    var img = this._img.stroke('#00f', 0.5);
    var lastX0, lastY0;
    for (var i = 0; i < this._observations.length; i++) {
      var x0 = this._leftMargin + this._barWidth * i;
      var y0 = this._height - (this._bottomMargin + this._minBarHeight +
                               (this._observations[i] - this._minValue) * this._beatHeight);
      img = img.drawLine(x0, y0, x0 + this._barWidth, y0);
      if (i > 0) {
        img = img.drawLine(lastX0, lastY0, x0, y0);
      }
      lastX0 = x0 + this._barWidth;
      lastY0 = y0;
    }
  }

  _drawHorizontalLines() {
    for (var hr = this._minValue; hr <= this._maxValue; hr++) {
      if (this._maxValue - this._minValue > 40 && hr % 5 != 0) {
        continue;
      }
      var labeledLine = (this._maxValue - this._minValue < 60 && hr % 5 == 0) || hr % 10 == 0;
      var y = this._height - (this._bottomMargin + this._minBarHeight + (hr - this._minValue) *
                              this._beatHeight);
      this._img.stroke((labeledLine ? "#000" : "#333"), 0.5).drawLine(
        this._leftMargin,
        y,
        this._width - this._rightMargin,
        y);
    }
  }

  _drawTimes() {
    
  }
}

exports.draw = function(width, height, observations, minuteIndexes, output, done) {
  new ImageDrawer(width, height, observations, minuteIndexes).draw(output, done);
}
