MAG_HEIGHT = 300;
IMG_WIDTH = 920;
MARGIN = 30;
MAG_WIDTH = (IMG_WIDTH + MARGIN * 2);
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
  var magnifierWidth = (NUM_OBS / data.length) * IMG_WIDTH;
  var $magnifier = $('<div>').attr('id', 'magnifier').css('width', magnifierWidth);
  var imageLeft = null;
  var draggingPos = null;
  $('#session').prepend($magnifier);
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
  updateMag(0);
}

function MagPanel(startObs) {
  this.$div = $('<div>').addClass('mag-panel');
  this.bars = []
  for (var i = 0; i < NUM_OBS; i++) {
    var $bar = $('<div>').addClass('mag-bar');
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
  var endObs = Math.min(startObs + NUM_OBS, data.length) - startObs;
  for (var i = 0; i < endObs; i++) {
    var obs = data[startObs + i];
    var height = (MAG_HEIGHT / 140) * (obs[2] - 35);
    this.bars[i].height(Math.max(0, Math.min(MAG_HEIGHT, height)));
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
  if (magPanels.length == 0) {
    addMag(startObs);
  }
  if (magPanels.length < 2 && startObs != magPanels[0].startObs) {
    addMag(magPanels[0].startObs + NUM_OBS);
  }
  var indexWithIntersection = findPanelWithIntersection(startObs);
  if (indexWithIntersection == -1) {
    magPanels[0].setStartObs(startObs);
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
