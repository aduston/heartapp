'use strict'

let Constants = {
  xLabelWidth: 60,
  minRate: 35,
  maxRate: 175,
  spaceTop: 5,
  spaceLeft: 30,
  spaceBottom: 25,
  regularStroke: '#00c',
  halvedStroke: '#f00',
  regularFill: 'rgba(0,0,255,0.7)',
  halvedFill: 'rgba(255,0,0,0.7)',
  maxNumBars: 600
};

class DataSummary {
  constructor(minSeconds, maxSeconds, minHR, maxHR, hasHalved) {
    this.minSeconds = minSeconds;
    this.maxSeconds = maxSeconds;
    this.minHR = minHR;
    this.maxHR = maxHR;
    this.hasHalved = hasHalved
  }
}

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
    outerRect.width - Constants.spaceLeft * 2,
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

class GraphDrawer {
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
    for (var hr = Constants.minRate; hr <= Constants.maxRate; hr++) {
      if (hr % 5 != 0) {
        continue;
      }
      var strokeStyle = '#aaa';
      var lineWidth = 0.8;
      if (hr % 20 == 0) {
        strokeStyle = '#000';
        lineWidth = 1.6;
      } else if (hr % 10 == 0) {
        strokeStyle = '#222';
      }
      var y = this._params.yForHR(hr);
      this._ctx.lineWidth = lineWidth;
      this._ctx.strokeStyle = strokeStyle;
      this._ctx.beginPath();
      this._ctx.moveTo(this._params.graphRect.x, y);
      this._ctx.lineTo(this._params.graphRect.maxX, y);
      this._ctx.stroke();
      if (hr % 10 == 0) {
        var te = this._ctx.measureText(hr + "");
        this._ctx.fillText(
          hr + "",
          this._params.graphRect.x - te.width - 2,
          y + (te.actualBoundingBoxAscent / 2));
        this._ctx.fillText(
          hr + "",
          this._params.graphRect.maxX + 2,
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
    let p = this._params;
    let labeledMultiple = this._findLabeledMultiple();
    this._ctx.fillStyle = Constants.regularFill;
    let startObs = Math.max(0, Math.floor(p.startObs));
    let endObs = Math.min(
      this._obs.length - 1,
      Math.ceil(p.startObs + p.numObs));
    var curX = p.graphRect.x;
    if (startObs < p.startObs) {
      curX -= (p.barWidth * (p.startObs - startObs));
    }
    var lastLabelX = 0;
    let firstSecond = this._obs[startObs].seconds;
    var nextLabelSeconds = Math.ceil(firstSecond / labeledMultiple) * labeledMultiple;
    for (var i = startObs; i <= endObs; i++) {
      let obs = this._obs[i];
      this._ctx.fillStyle = obs.halved ? Constants.halvedFill : Constants.regularFill;
      let y = p.yForHR(obs.heartRate);
      let x = Math.max(p.graphRect.x, curX);
      let nextX = Math.min(curX + p.barWidth, p.graphRect.maxX);
      this._ctx.fillRect(
        x, y, nextX - x, p.graphRect.maxY - y);
      if (obs.seconds >= nextLabelSeconds && (lastLabelX == 0 || lastLabelX < x - Constants.xLabelWidth / 2.0)) {
        lastLabelX = this._drawXLabel((x + nextX) / 2.0, nextLabelSeconds);
        nextLabelSeconds += labeledMultiple;
      }
      curX = nextX;
    }
  }

  _drawNarrowValues() {
    let p = this._params;
    let labeledMultiple = this._findLabeledMultiple();
    let obsPerBar = p.numObs / Constants.maxNumBars;
    let pixelsPerObs = p.graphRect.width / p.numObs;
    let pixelsPerBar = p.graphRect.width / Constants.maxNumBars;
    let obsStartX = p.graphRect.x - p.startObs * pixelsPerObs;
    var barIndex = p.startObs / obsPerBar;
    var x = obsStartX + barIndex * pixelsPerBar;
    var lastLabelX = 0;
    let firstSecond = this._obs[Math.max(0, Math.min(p.startObs, this._obs.length - 1))].seconds;
    var nextLabelSeconds = Math.ceil(firstSecond / labeledMultiple) * labeledMultiple;
    while (x < p.graphRect.maxX) {
      if (x + pixelsPerBar < p.graphRect.x) {
        continue;
      }
      let summary = this._dataSummary(barIndex * obsPerBar, (barIndex + 1) * obsPerBar);
      let maxY = p.yForHR(summary.maxHR);
      let minY = p.yForHR(summary.minHR);
      let strokeStyle = summary.hasHalved ? Constants.halvedStroke : Constants.regularStroke;
      let fillStyle = summary.hasHalved ? Constants.halvedFill : Constants.regularFill;
      let lineX = this._drawGraphValueLine(x, minY, maxY, pixelsPerBar, strokeStyle);
      this._drawGraphValueLine(x, p.graphRect.maxY, maxY, pixelsPerBar, fillStyle);
      if (lastLabelX == 0 || lastLabelX < x - Constants.xLabelWidth / 2.0) {
        let newLabelX = this._maybeDrawXLabel(summary, nextLabelSeconds, lineX);
        if (newLabelX != 0) {
          lastLabelX = newLabelX;
          nextLabelSeconds += labeledMultiple;
        }
      }
      barIndex += 1;
      x = obsStartX + barIndex * pixelsPerBar;
    }
  }

  _maybeDrawXLabel(summary, nextLabelSeconds, lineX) {
    for (var seconds = summary.minSeconds; seconds <= summary.maxSeconds; seconds++) {
      if (seconds >= nextLabelSeconds) {
        return this._drawXLabel(lineX, nextLabelSeconds);
      }
    }
    return 0.0;
  }

  _drawXLabel(midX, seconds) {
    this._ctx.lineWidth = 1;
    this._ctx.strokeStyle = '#000';
    this._ctx.beginPath();
    this._ctx.moveTo(midX, this._params.graphRect.maxY);
    this._ctx.lineTo(midX, this._params.graphRect.maxY + 5);
    this._ctx.stroke();
    let label = this._timeLabelText(seconds);
    var te = this._ctx.measureText(label);
    this._ctx.fillStyle = '#000';
    this._ctx.fillText(
      label,
      midX - te.width / 2.0,
      this._params.graphRect.maxY + te.actualBoundingBoxAscent + 7);
    return midX + te.width / 2.0;
  }

  _timeLabelText(seconds) {
    function pad(num) {
      var num = num + '';
      return num.length == 1 ? ('0' + num) : num;
    }
    if (seconds < 60) {
      return '0:' + pad(seconds);
    } else if (seconds < 3600) {
      return Math.floor(seconds / 60) + ':' + pad(seconds % 60, 2);
    } else {
      return Math.floor(seconds / 3600) + ':' +
        pad(Math.floor((seconds % 3600) / 60), 2) + ':' +
        pad(seconds % 60, 2);
    }
  }

  _drawGraphValueLine(x, y0, y1, width, style) {
    let p = this._params;
    let lineMinX = Math.max(x, p.graphRect.x);
    let actualWidth = Math.min(width, x + width - p.graphRect.minX, p.graphRect.maxX - x);
    let lineX = lineMinX + actualWidth / 2.0;
    this._ctx.lineWidth = actualWidth;
    this._ctx.strokeStyle = style;
    this._ctx.beginPath();
    this._ctx.moveTo(x, y0);
    this._ctx.lineTo(x, y1);
    this._ctx.stroke();
    return lineX;
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

  _dataSummary(startObs, endObs) {
    let minIndex = Math.max(Math.floor(startObs), 0);
    let maxIndex = Math.min(Math.ceil(endObs), this._obs.length - 1);
    let summary = new DataSummary(10000000000, 0, 250, 0, false);
    for (var i = minIndex; i <= maxIndex; i++) {
      if (this._obs[i].seconds < summary.minSeconds) {
        summary.minSeconds = this._obs[i].seconds;
      }
      if (this._obs[i].seconds > summary.maxSeconds) {
        summary.maxSeconds = this._obs[i].seconds;
      }
      if (this._obs[i].halved) {
        summary.hasHalved = true;
      }
      if (this._obs[i].heartRate < summary.minHR) {
        summary.minHR = this._obs[i].heartRate;
      }
      if (this._obs[i].heartRate > summary.maxHR) {
        summary.maxHR = this._obs[i].heartRate;
      }
    }
    return summary;
  }
}

module.exports = GraphDrawer;
