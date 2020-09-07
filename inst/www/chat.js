function showResultsPlot(opts) {
  var myChart = Highcharts.chart('quiz-results-plot',opts);
}

// Edit input leaves focus
$(document).on("blur", ".qu-edit",function(e) {
  var obj = e.currentTarget;
  var id = obj.id;
  var val = $(obj).val();
  Shiny.onInputChange("qu-edit-blur", {eventId:"qu-edit-blur",id: "qu-edit-blur", input_id: id, value: val, nonce: Math.random()});
});

startQuizRunTime = function() {
  window.quizTimeMode="runtime";
  window.quizStartTime = (new Date()).getTime();
  clearTimeout(window.quizTimer);
  window.quizTimer = setInterval(showQuizRunTime, 1000);
};
stopQuizTimer = function() {
  clearTimeout(window.quizTimer);
};

startQuizCountdown = function(secs) {
  window.quizTimeMode="countdown";
  window.quizEndTime = (new Date()).getTime() + secs*1000;
  clearTimeout(window.quizTimer);
  window.quizTimer = setInterval(showQuizRunTime, 1000);
};


showQuizRunTime = function() {
  var curTime = (new Date()).getTime();
  if (window.quizTimeMode == "runtime") {
    secs = Math.round((curTime - window.quizStartTime) / 1000);
    if (secs>10) {
      secs = Math.floor(secs/10)*10;
    }
    msg = "("+secs.toString()+ " sec.)";
  } else {
    // countdown
    secs = Math.round((window.quizEndTime-curTime) / 1000);
    if (secs>10) {
      secs = Math.floor(secs/10)*10;
      msg = "(still > "+secs.toString()+ " sec.)";
    } else if (secs > 0) {
      msg = "(just "+secs.toString()+ " sec.)";
    } else {
      msg = "Time is up!";
    }
  }
  $("#quiz-time").html(msg);
};


showQuizPane = function(pane, panes = ["quizEdit","quizShow","quizResults"]) {
  $("#"+pane+"UI").removeClass("invisible");
  $("#"+pane+"Btn").addClass("btn-qc-toogled");

  for (var i = 0; i < panes.length; i++) {
    p = panes[i];
    if (p != pane) {
      $("#"+p+"UI").addClass("invisible");
      $("#"+p+"Btn").removeClass("btn-qc-toogled");
    }
  }
};


function setQuizResultsPane() {
  showQuizPane("quizResults");
}

function setInvisible(sel) {
  $(sel).addClass("invisible");
}

function setVisible(sel) {
  $(sel).removeClass("invisible");
}

$(document).on("click","#quizShowBtn", function (e) {
  showQuizPane("quizShow");
});
$(document).on("click","#quizEditBtn", function (e) {
  showQuizPane("quizEdit");
});
$(document).on("click","#quizResultsBtn", function (e) {
  showQuizPane("quizResults");
});

$(document).on("click","#btn-chat-send", function (e) {
  chatSendEvent();
});

$(document).on("keypress","#chat-input", function (e) {
  if(e.which === 13){
    chatSendEvent();
  }
});

$(document).on("click","#btn-quiz-start", function (e) {
  var val = shinyEventsWidgetValue($("#quiz-timer"));
  Shiny.onInputChange("quizStartEvent", {eventId: "quizStartEvent", id: "quizStartEvent", value: val, nonce: Math.random()});
});



$(document).on("click","#btn-quiz-send", function (e) {
  quizSendEvent();
});

function quizSendEvent() {
  var val = shinyEventsWidgetValue($("#quiz-choices"));

  if (typeof val === 'undefined') {
    val = "NA";
    //$("#quiz-msgUI").html("Please first choose an answer by clicking on it.");
    //return;
  }

  Shiny.onInputChange("quizSendEvent", {eventId: "quizSendEvent", id: "quizSendEvent", value: val, nonce: Math.random()});
}

function chatSendEvent() {
  var msg = $("#chat-input").val();
  if (msg=="") return;
  Shiny.onInputChange("chatSendEvent", {eventId: "chatSendEvent", id: "chatSendEvent", value: msg, nonce: Math.random()});
  $("#chat-input").val("");
}



function insertChat(msg, user, initials, time, color){
    html = '<li class="left clearfix">'+
    '<span class="circle pull-left" style="background-color: '+color+';"><span class="initials">'+initials+'</span></span>'+
    '<div class="chat-body clearfix">'+
      '<div class="header">'+
        '<strong class="primary-font">'+user+'</strong> <small class="pull-right text-muted">'+
          '<span class="glyphicon glyphicon-time"></span>'+ time+'</small>'+
      '</div>'+
      '<p>'+msg+'</p>'+
    '</div>'+
'</li>';
  $('#chat-ul').append(html);
  $('#chat-body').scrollTop($('#chat-body').prop('scrollHeight'));

}
