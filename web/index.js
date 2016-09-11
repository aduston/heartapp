function SessionData(arr) {
  this.timestamp = arr[0];
  this.version = arr[1];
  this.duration = arr[2];
  this.numThreshold = arr[3];
  if (arr.length > 4) {
    this.mean = arr[4];
    this.min = arr[5];
    this.max = arr[6];
  }
}

SessionData.PAGE_SIZE = 10;
SessionData.all = [];
SessionData.numInDOM = 0;
SessionData.anyMissingFromDOM = function() {
  return SessionData.numInDOM < SessionData.all.length;
};

SessionData.prototype.formattedTimestamp = function() {
  return moment.unix(this.timestamp).tz('America/New_York').format('M/D/YYYY h:mm a');
};

SessionData.prototype.formattedDuration = function() {
  function pad(num) {
    var num = num + '';
    return num.length == 1 ? ('0' + num) : num;
  }
  if (this.duration < 60) {
    return '0:' + pad(this.duration);
  } else if (this.duration < 3600) {
    return Math.floor(this.duration / 60) + ':' + pad(this.duration % 60, 2);
  } else {
    return Math.floor(this.duration / 3600) + ':' +
      pad(Math.floor((this.duration % 3600) / 60), 2) + ':' +
      pad(this.duration % 60, 2);
  }

};

SessionData.prototype.imageURL = function() {
  var imgUrl = window.LOCAL ? 'https://adamsheart.com' : '';
  return imgUrl + '/' + this.timestamp + '.' + this.version + '.png'
};

SessionData.prototype.statsText = function() {
  return ["mean ", this.mean, " / min ", this.min,
          " / max ", this.max, " / count ", this.numThreshold].join('');
};

for (var i = 0; i < sessions.length; i++) {
  SessionData.all.push(new SessionData(sessions[i]));
}

function ImageElement($img) {
  this.$img = $img;
  this.top = $img.position().top;
  this.height = $img.height();
}

ImageElement.all = [];

function needsMoreSessions() {
  return $('#more-sessions').offset().top - 200 < $(window).scrollTop() + $(window).height();
}

function onScroll(e) {
  if (SessionData.anyMissingFromDOM() && needsMoreSessions()) {
    var numToAdd = Math.min(SessionData.PAGE_SIZE, SessionData.all.length - SessionData.numInDOM);
    for (var i = SessionData.numInDOM; i < SessionData.numInDOM + numToAdd; i++) {
      var sessionData = SessionData.all[i];
      var $img = $('<img>').attr('src', sessionData.imageURL()).
          attr({ 'width': 980, 'height': 220 });
      var $div = $('<div>').attr('id', 'session-' + sessionData.timestamp).
          append($('<a>').attr('href', '/' + sessionData.timestamp).text(sessionData.formattedTimestamp())).
          append('<br>').
          append($('<span>').text('duration ' + sessionData.formattedDuration())).
          append('<br>');
      if (sessionData.mean) {
        $div.append($('<span>').text(sessionData.statsText())).append('<br>');
      }
      $div.append($('<a>').attr('href', '/' + sessionData.timestamp).append($img));
      $('#sessions').append($div);
      ImageElement.all.push($img);
    }
    SessionData.numInDOM += numToAdd;
    if (!SessionData.anyMissingFromDOM()) {
      $('#more-sessions').remove();
    }
  }
}

$(function() {
  $('#sessions img').each(function(i) { ImageElement.all.push($(this)); });
  $(window).scroll(onScroll);
});
