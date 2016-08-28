'use strict'

let Constants = {
  xLabelWidth: 60,
  minRate: 35,
  maxRate: 175,
  spaceTop: 5,
  spaceLeft: 30,
  spaceBottom: 25,
  regularStroke: '#00c',
  halvedStroke: 'rgba(255,0,0,0.7)',
  regularFill: 'rgba(0,0,255,0.7)',
  halvedFill: '#f00',
  maxNumBars: 180
};

class Rect {
  constructor(x, y, width, height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  get minX() {
    return this.x;
  }

  get maxX() {
    return this.x + this.width;
  }

  get minY() {
    return this.y;
  }

  get maxY() {
    return this.y + this.height;
  }
}

function graphRect(outerRect) {
  return new Rect(
    outerRect.x + Constants.spaceLeft,
    outerRect.y + Constants.spaceTop,
    outerRect.width - Constants.spaceLeft,
    outerRect.height - Constants.spaceBottom - Constants.spaceTop);
};

class ChartParams {
  constructor(outerRect, startObs, numObs) {
    this.graphRect = graphRect(outerRect);
    this.beatHeight = this.graphRect.height / (Constants.maxRate - Constants.minRate);
    this.barWidth = this.graphRect.width / numObs;
    this.startObs = startObs;
    this.numObs = numObs;
  }

  yForHR(hr) {
    let clampedHR = Math.max(Constants.minRate, Math.min(Constants.maxRate, hr));
    return this.graphRect.maxY - (clampedHR - Constants.minRate) * this.beatHeight;
  }
}

class ImageDrawer {
  constructor(width, height, observationObjs) {
    this._outerRect = new Rect(0, 0, width, height);
    this._obs = observationObjs;
  }

  draw(canvas, startObs, numObs) {
    this._ctx = canvas.getContext('2d');
    this._params = new ChartParams(this._outerRect, startObs, numObs);
    this._ctx.fillStyle = "#fff";
    this._ctx.fillRect(0, 0, this._width, this._height);
    this._drawHorizontalLines();
    this._drawValues();
  }

  _drawHorizontalLines() {
    this._ctx.fillStyle = '#000';
    this._ctx.font = '12px Courier';
    this._ctx.lineWidth = 1;
    for (var hr = Constants.minRate; hr <= Constants.maxRate; hr++) {
      if (hr % 5 != 0) {
        continue;
      }
      var labeledLine = hr % 10 == 0;
      var y = this._params.yForHR(hr);
      this._ctx.strokeStyle = labeledLine ? "#000" : "#666";
      this._ctx.beginPath();
      this._ctx.moveTo(this._params.graphRect.x, y);
      this._ctx.lineTo(this._params.graphRect.maxX, y);
      this._ctx.stroke();
      if (labeledLine) {
        var te = this._ctx.measureText(hr + "");
        this._ctx.fillText(
          hr + "",
          this._params.graphRect.x - te.width - 2,
          y + (te.actualBoundingBoxAscent / 2));
      }
    }
  }


  _drawValues() {
    if (this._params.numObs <= Constants.maxNumBars) {
      this._drawWideValues();
    } else {
      this._drawNarrowValues();
    }
  }

  _drawWideValues() {
    let labeledMultiple = this._findLabeledMultiple();
    this._ctx.fillStyle = Constants.regularFill;
    let startObs = Math.max(0, Math.floor(this._params.startObs));
    let endObs = Math.min(
      this._obs.length - 1,
      Math.ceil(this._params.startObs + this._params.numObs));
    var inHasHalved = false;
    var curX = this._params.graphRect.x;
    if (startObs < this._params.startObs) {
      curX -= (this._params.barWidth * (this._params.startObs - startObs));
    }
    var lastLabelX = 0;
    for (var i = startObs; i <= endObs; i++) {
      let obs = this._obs[i];
      if (obs.halved != inHasHalved) {
        this._ctx.fillStyle = obs.halved ? Constants.halvedFill : Constants.regularFill;
        inHasHalved = obs.halved;
      }
      let y = this._params.yForHR(obs.heartRate);
      console.log(obs.heartRate, y);
      let x = Math.max(this._params.graphRect.x, curX);
      let nextX = Math.min(curX + this._params.barWidth, this._params.graphRect.maxX);
      this._ctx.fillRect(
        x, y, nextX - x, this._params.graphRect.maxY - y);
      curX = nextX;
    }
  }

  _drawNarrowValues() {
    this._drawNarrowValues();
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

  _findLabeledMultiple() {
    let maxNumLabels = this._params.graphRect.width / Constants.xLabelWidth;
    let obsPerLabel = Math.floor(this._params.numObs / maxNumLabels);
    let intervals = [5, 15, 30, 60, 300, 600, 900, 1800, 3600, 7200];
    for (var i = 0; i < intervals.length; i++) {
      if (obsPerLabel < intervals[i]) {
        return intervals[i];
      }
    }
    return 18000;
  }
}

exports.ImageDrawer = ImageDrawer;
