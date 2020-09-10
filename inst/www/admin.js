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



$(document).on("click","#btn-quiz-add-choice", function (e) {
  var choice = shinyEventsWidgetValue($("#quiz-answers-edit"));
  if (typeof choice === 'undefined') {
    choice = "NA";
  }
  Shiny.onInputChange("quizAddRemoveChoice", {eventId: "quizAddRemoveChoice", id: "add-choice", value: choice, nonce: Math.random()});
});

$(document).on("click","#btn-quiz-del-choice", function (e) {
  var choice = shinyEventsWidgetValue($("#quiz-answers-edit"));
  if (typeof choice === 'undefined') {
    choice = "NA";
  }
  Shiny.onInputChange("quizAddRemoveChoice", {eventId: "quizAddRemoveChoice", id: "del-choice", value: choice, nonce: Math.random()});
});

$(document).on("click","#btn-quiz-start", function (e) {
  var val = shinyEventsWidgetValue($("#quiz-timer"));
  Shiny.onInputChange("quizStartEvent", {eventId: "quizStartEvent", id: "quizStartEvent", value: val, nonce: Math.random()});
});

