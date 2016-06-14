'use strict'

// uses https://github.com/Automattic/node-canvas

var Canvas = require('canvas');
var fs = require('fs');

var Image = Canvas.Image;

class ImageDrawer {
  constructor(width, height, observations, minuteIndexes) {
    this._canvas = new Canvas(width, height);
    this._ctx = this._canvas.getContext('2d');
    
    this._width = width;
    this._height = height;
    this._observations = observations;
    this._minuteIndexes = minuteIndexes;

    this._topMargin = 10;
    this._bottomMargin = 20;
    this._leftMargin = 30;
    this._rightMargin = 30;

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
    var maxBarHeight = this._height - this._topMargin - this._bottomMargin; 
    this._beatHeight = maxBarHeight / (this._maxValue - this._minValue);
  }

  draw(output, done) {
    this._ctx.fillStyle = "#fff";
    this._ctx.fillRect(0, 0, this._width, this._height);
    this._drawHorizontalLines();
    this._drawValues();
    this._drawTimes();
    this._canvas.toBuffer(function(err, buf) {
      if (err == null) {
        fs.writeFile(output, buf);
      }
      done(err);
    });
  }

  _drawValues() {
    if (this._barWidth > 1.0) {
      this._drawWideValues();
    } else {
      this._ctx.strokeStyle = '#00f';
      var totalWidth = this._width - this._leftMargin - this._rightMargin
      for (var i = 0; i < totalWidth; i++) {
        var minMax = this._minAndMaxAt(i, totalWidth);
        var min = minMax[0];
        var max = minMax[1];
        var x = this._leftMargin + i;
        var y0 = this._height - (this._bottomMargin + (max - this._minValue) * this._beatHeight);
        this._ctx.beginPath();
        this._ctx.lineTo(x, y0);
        this._ctx.lineTo(x, y0 + (max - min) * this._beatHeight);
        this._ctx.stroke();
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
    this._ctx.strokeStyle = '#00f';
    this._ctx.lineWidth = 3;
    this._ctx.beginPath();
    for (var i = 0; i < this._observations.length; i++) {
      var x0 = this._leftMargin + this._barWidth * i;
      var y0 = this._height - (this._bottomMargin + (this._observations[i] - this._minValue) * this._beatHeight);
      this._ctx.lineTo(x0, y0);
      this._ctx.lineTo(x0 + this._barWidth, y0);
    }
    this._ctx.stroke();
  }

  _drawHorizontalLines() {
    this._ctx.fillStyle = '#000';
    this._ctx.font = '12px Courier';
    this._ctx.lineWidth = 1;
    for (var hr = this._minValue; hr <= this._maxValue; hr++) {
      if (this._maxValue - this._minValue > 40 && hr % 5 != 0) {
        continue;
      }
      var labeledLine = (this._maxValue - this._minValue < 60 && hr % 5 == 0) || hr % 10 == 0;
      var y = this._height - (this._bottomMargin + (hr - this._minValue) * this._beatHeight);
      this._ctx.strokeStyle = labeledLine ? '#000' : '#999';
      this._ctx.beginPath()
      this._ctx.lineTo(this._leftMargin, y);
      this._ctx.lineTo(this._width - this._rightMargin, y);
      this._ctx.stroke();
      if (labeledLine) {
        var te = this._ctx.measureText(hr + "");
        this._ctx.fillText(
          hr + "",
          this._leftMargin - te.width - 2,
          y + (te.actualBoundingBoxAscent / 2));
      }
    }
  }
  _drawTimes() {
    
  }
}

exports.draw = function(width, height, observations, minuteIndexes, output, done) {
  new ImageDrawer(width, height, observations, minuteIndexes).draw(output, done);
}
