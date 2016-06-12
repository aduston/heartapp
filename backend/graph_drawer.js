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
    this._barPadding = 3;
    this._minBarHeight = 10;

    this._minValue = Math.min.apply(Math, this._observations);
    this._maxValue = Math.max.apply(Math, this._observations);
    if (this._maxValue % 10 != 0) {
      this._maxValue += (10 - (this._maxValue % 10));
    }
    if (this._minValue % 10 != 0) {
      this._minValue -= (this._minValue % 10);
    }
    this._barWidth = Math.floor(
      (this._width - this._leftMargin - this._rightMargin - this._barPadding) /
        this._observations.length) - this._barPadding;
    var maxBarHeight = this._height - this._topMargin - this._bottomMargin - this._minBarHeight; 
    this._beatHeight = maxBarHeight / (this._maxValue - this._minValue);
  }

  draw(output, done) {
    this._drawBars();
    this._drawHorizontalLines();
    this._drawTimes();
    this._img.write(output, done);
  }

  _drawBars() {
    for (var i = 0; i < this._observations.length; i++) {
      var x0 = this._leftMargin + this._barPadding + (this._barWidth + this._barPadding) * i;
      var y0 = this._height - (this._bottomMargin + this._minBarHeight +
                               (this._observations[i] - this._minValue) * this._beatHeight);
      this._img.fill("#00f").drawRectangle(
        x0,
        y0,
        x0 + this._barWidth,
        this._height - (this._bottomMargin - this._minBarHeight)
      );
    }
  }

  _drawHorizontalLines() {
    for (var hr = this._minValue; hr <= this._maxValue; hr++) {
      if (this._maxValue - this._minValue > 40 && hr % 5 != 0) {
        continue;
      }
      var labeledLine = (this._maxValue - this._minValue < 60 && i % 5 == 0) || hr % 10 == 0;
      var y = this._height - (this._bottomMargin + this._minBarHeight + (hr - this._minValue) *
                              this._beatHeight);
      this._img.stroke((labeledLine ? "#333" : "#333"), 1).drawLine(
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
