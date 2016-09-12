MAG_HEIGHT = 300;
IMG_WIDTH = 920;
MARGIN = 30;
MAX_HR = 175;
MIN_HR = 35;
TIME_INTERVAL = 60;
MAG_WIDTH = IMG_WIDTH;
NUM_OBS = MAG_WIDTH / 2;

var jqueryLoaded = false;
var data = null;

$.getJSON('/' + timestamp + '.json', function(resp) {
  data = resp;
  $('#magnified').empty();
  load();
});

$(function() {
  jqueryLoaded = true;
  load();
});

function load() {
  if (data == null || !jqueryLoaded) {
    return;
  }
  var startObs = 0;
  try {
    startObs = parseInt(document.location.hash.substring(1));
  } catch (e) {}
  if (isNaN(startObs)) startObs = 0;
  startObs = Math.max(0, Math.min(data.length - NUM_OBS, startObs));
  var magnifierWidth = (NUM_OBS / data.length) * IMG_WIDTH;
  var $magnifier = $('<div>').attr('id', 'magnifier').css('width', magnifierWidth);
  $('#session').prepend($magnifier);
  if (startObs != 0) {
    $magnifier.css('left', MARGIN + startObs * (IMG_WIDTH / data.length));
  }
  var imageLeft = null;
  var draggingPos = null;
  var magnifierTop = $magnifier.offset().top;
  $magnifier.on('mousedown', function(e) {
    imageLeft = $('#session img').offset().left;
    draggingPos = $magnifier.offset().left - e.pageX;
  });
  $(document.body).on('mousemove', function(e) {
    if (draggingPos == null) {
      return;
    }
    var newLeft = Math.max(
      imageLeft + MARGIN,
      Math.min(imageLeft + MARGIN + IMG_WIDTH - magnifierWidth,
               e.pageX + draggingPos));
    $magnifier.offset({
      top: magnifierTop,
      left: newLeft
    });
    updateMag(Math.floor(((newLeft - MARGIN - imageLeft) / IMG_WIDTH) * data.length));
  });
  $(document.body).on('mouseup', function(e) {
    draggingPos = null;
  });
  updateMag(startObs);
}

function MagPanel(startObs) {
  this.$div = $('<div>').addClass('mag-panel');
  this.bars = []
  for (var i = 0; i < NUM_OBS; i++) {
    var $bar = $('<div>').addClass('mag-bar').css('left', i * 2);
    this.bars.push($bar);
    this.$div.append($bar);
  }
  this.setStartObs(startObs);
};

MagPanel.prototype.setStartObs = function(startObs) {
  if (startObs == this.startObs) {
    return;
  }
  this.startObs = startObs;
  this.$div.find('.time').remove();
  var endObs = Math.min(startObs + NUM_OBS, data.length) - startObs;
  var nextTime = this.determineLabelTime(startObs);
  for (var i = 0; i < endObs; i++) {
    var obs = data[startObs + i];
    var height = (MAG_HEIGHT / (MAX_HR - MIN_HR)) * (obs[2] - MIN_HR);
    this.bars[i].height(Math.max(0, Math.min(MAG_HEIGHT, height)));
    if (obs[0] >= nextTime) {
      this.addTimeLabel(nextTime, i);
      nextTime += TIME_INTERVAL;
    }
  }
};

MagPanel.prototype.addTimeLabel = function(time, index) {
  var labelText = this.formattedDuration(time);
  this.$div.append($('<div>').addClass('time').css('left', index * 2 - 40).text(labelText));
};

MagPanel.prototype.formattedDuration = function(time) {
  function pad(num) {
    var num = num + '';
    return num.length == 1 ? ('0' + num) : num;
  }
  if (time < 60) {
    return '0:' + pad(time);
  } else if (time < 3600) {
    return Math.floor(time / 60) + ':' + pad(time % 60, 2);
  } else {
    return Math.floor(time / 3600) + ':' +
      pad(Math.floor((time % 3600) / 60), 2) + ':' +
      pad(time % 60, 2);
  }
};

MagPanel.prototype.determineLabelTime = function(index) {
  var startIndex = Math.max(0, index - 3);
  var time = data[startIndex][0];
  var mark = TIME_INTERVAL * Math.ceil(time / TIME_INTERVAL);
  if (index == 0 || data[index - 1][0] < mark) {
    return mark;
  } else {
    return mark + TIME_INTERVAL;
  }
};

MagPanel.prototype.hasIntersection = function(startObs) {
  return this.startObs < startObs + NUM_OBS && this.startObs + NUM_OBS > startObs;
};

MagPanel.prototype.setLeftPos = function(startObs) {
  this.$div.css('left', -((startObs - this.startObs) / NUM_OBS) * MAG_WIDTH);
};

MagPanel.prototype.makeFirst = function() {
  this.$div.remove()
  $('#magnified').prepend(this.$div);
};

var magPanels = [];

function findPanelWithIntersection(startObs) {
  for (var i = 0; i < 2; i++) {
    if (magPanels[i].hasIntersection(startObs)) {
      return i;
    }
  }
  return -1;
}

function addMag(startObs) {
  var magPanel = new MagPanel(startObs);
  $('#magnified').append(magPanel.$div);
  magPanels.push(magPanel);
}

function updateMag(startObs) {
  document.location.hash = startObs + '';
  if (magPanels.length == 0) {
    addMag(startObs - (startObs % NUM_OBS));
  }
  if (magPanels.length < 2 && startObs != magPanels[0].startObs) {
    addMag(magPanels[0].startObs + NUM_OBS);
  }
  var indexWithIntersection = findPanelWithIntersection(startObs);
  if (indexWithIntersection == -1) {
    magPanels[0].setStartObs(startObs - (startObs % NUM_OBS));
    magPanels[0].makeFirst();
    magPanels[0].setLeftPos(startObs);
  } else {
    var panel0 = magPanels[indexWithIntersection];
    var panel1 = magPanels[(indexWithIntersection + 1) % 2];
    if (panel0.startObs < startObs && panel1.startObs < panel0.startObs) {
      panel1.setStartObs(panel0.startObs + NUM_OBS);
      panel0.makeFirst();
    } else if (panel0.startObs > startObs && panel1.startObs > panel0.startObs) {
      panel1.setStartObs(panel0.startObs - NUM_OBS);
      panel1.makeFirst();
    }
    panel0.setLeftPos(startObs);
    if (panel1) {
      panel1.setLeftPos(startObs);
    }
  }
}
