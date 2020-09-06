
init.admin.app.instance = function(app=getApp()) {
  glob=app$glob
  glob$app.counter = glob$app.counter+1
  app$idnum = glob$app.counter
  app$user = random.nickname(sep=" ")
  app$initials = make.initials(app$user)
  init.chat.app.instance(app)
  init.admin.handlers()
  show.admin.ui()
}


show.admin.ui = function(app=getApp()) {
  qu = app$glob$cur.qu
  ui = tagList(
    br(),
    quiz.admin.outer.ui(qu),
    chat.ui()
  )
  setUI("mainUI",ui)
  # Note that quizResultsUI must be initially visible
  # but can be hidden now. Otherwise highcharter plots
  # are not correctly shown
  callJS("showQuizPane","quizShow")
}

init.admin.handlers = function(app=getApp()) {
  glob = app$glob
  eventHandler("quizStartEvent",fun =  function(value, ..., app=getApp()) {
    start.quiz(timer=as.integer(value))
  })

  selectChangeHandler("quiz-timer",fun =  function(value, ..., app=getApp()) {
    restore.point("change-quiz-timer")
    if (!glob$quiz.runs) return()
    admin.set.quiz.timer(as.integer(value))
    glob$rv.timer.change.nonce(runif(1))
  })

  buttonHandler("btn-quiz-stop", function(..., app=getApp()) {
    stop.quiz()
  })

  observeEvent(glob$rv.send.nonce(), {
    nonce = glob$rv.send.nonce()
    if (nonce != 0) {
      quiz.admin.send.event()
    }
  })
}

set.quiz = function(qu, app=getApp()) {
  glob=app$glob
  glob$cur.qu = qu
  glob$quiz.runs = FALSE
}


start.quiz = function(timer=NA,app=getApp()) {
  restore.point("start.quiz")
  glob = app$glob
  qu = glob$cur.qu
  if (is.null(qu)) {
    warning("Tried to start quiz even though no quiz was set.")
    return(NULL)
  }
  if (is.null(glob$ans.df)) {
    n = max(50, round(glob$app.counter*1.1))
    glob$ans.df = data.frame(idnum=1:n, choice = NA_integer_)
  } else {
    glob$ans.df$choice = NA_integer_
  }
  glob$num.send = glob$num.resend = 0
  glob$quiz.runs = TRUE
  glob$quiz.start.timer = Sys.time()

  # Adapt admin UI
  evalJS('$("#btn-quiz-start").addClass("invisible");
          $("#btn-quiz-stop").removeClass("invisible");')
  setInnerHTML("num-send",paste0(app$glob$num.send, " replies."))
  admin.set.quiz.timer(timer)
  glob$rv.start.nonce(runif(1))
}

admin.set.quiz.timer = function(timer, app=getApp()) {
  glob = app$glob
  if (!glob$quiz.runs) return()
  glob$timer = timer
  if (is.na(timer)) {
    callJS("startQuizRunTime");
  } else {
    callJS("startQuizCountdown",timer);
  }
}

stop.quiz = function(app=getApp()) {
  glob = app$glob
  glob$quiz.runs = FALSE
  glob$res.qu = glob$cur.qu
  # Adapt admin UI
  glob$rv.stop.nonce(runif(1))
  evalJS('$("#btn-quiz-start").removeClass("invisible");
          $("#btn-quiz-stop").addClass("invisible");')
  callJS("stopQuizRunTime")
  callJS("setQuizResultsPane")
  show.quiz.results()
}


quiz.admin.outer.ui = function(qu=app$glob$cur.qu, app=getApp()) {
  quiz.runs = app$glob$quiz.runs

  html = paste0('
<div id="quiz-outer" class="col-md-6">
  <div class="panel panel-primary">
    <div class="panel-heading">
        Quiz
        <button class="btn btn-qc btn-xs" class="quiz-tab-btn" id="quizShowBtn"
       style="margin-left: 2em;">Show</button>
        <button class="btn btn-qc btn-xs" class="quiz-tab-btn" id="quizEditBtn"
       style="">Edit</button>
        <button class="btn btn-qc btn-xs" class="quiz-tab-btn" id="quizResultsBtn"
       style="">Results</button>

    </div>
    <div id="quiz-body" class="panel-body" style="height: 25em">
      <div id="quizShowUI" class="shiny-html-output" >', quiz.set.admin.show.ui(qu, TRUE), '
      </div>
      <div id="quizEditUI" class="shiny-html-output invisible">', quiz.set.edit.ui(qu, TRUE),'</div>
      <div id="quizResultsUI" class="not-invisible">
        <div id="quiz-results-question" class="invisible"></div>
        <div id="quiz-results-plot" style="width:100%; height:14em; " class="highchart html-widget html-widget-output"></div>
        <div id="quiz-results-table" style="width:100%; height:14em;" class="highchart html-widget html-widget-output invisible"></div>
      </div>
    </div>
  <div class="panel-footer">
    <button class="btn btn-start btn-sm', if(quiz.runs) ' invisible', '" id="btn-quiz-start">Start</button>
    <button class="btn btn-stop btn-sm', if(!quiz.runs) ' invisible', '" id="btn-quiz-stop">Stop</button>
    <select name="quiz-timer" id="quiz-timer" class="quiz-select" data-style="btn-qc">
      <option value="NA">No timer</option>
      <option value="10">10 Sec</option>
      <option value="30">30 Sec</option>
      <option value="60">1 Min</option>
      <option value="120">2 Min</option>
      <option value="180">3 Min</option>
      <option value="300">5 Min</option>
    </select>
    <span style="padding-left: 1em" id="num-send"></span>
    <span style="padding-left: 1em" id="quiz-time"></span>
  </div>

  </div>
</div>
')

  HTML(html)
}

quiz.set.admin.show.ui = function(qu, return.html=FALSE) {
  if (is.null(qu)) return(NULL)
  #btns = quiz.start.stop.btns()
  ui = qu$client.ui
  if (return.html) return(as.character(ui))
  setUI("quizShowUI", ui)
  dsetUI("quizShowUI", ui)
  textInput("id","lab","txt")
}

quiz.start.stop.btns = function(quiz.runs = getApp()$glob$quiz.runs, as.html = FALSE) {
  restore.point("quiz.start.stop.btns")
  html = paste0('
  <button class="btn btn-start btn-sm', if(quiz.runs) ' invisible', '" id="btn-quiz-start">Start</button>
  <button class="btn btn-stop btn-sm', if(!quiz.runs) ' invisible', '" id="btn-quiz-stop">Stop</button>
  <select name="quiz-timer" id="quiz-timer" class="quiz-select" data-style="btn-qc">
    <option value="NA">No timer</option>
    <option value="10">10 Sec</option>
    <option value="30">30 Sec</option>
    <option value="60">1 Min</option>
    <option value="120">2 Min</option>
    <option value="180">3 Min</option>
    <option value="300">5 Min</option>
  </select>
  <span id="num-send"></span>
  <span style="padding-left: 1em" id="quiz-time"></span>
  ')
  if (as.html) return(html)
  HTML(html)
}

quiz.set.edit.ui = function(qu, return.html=FALSE) {
  restore.point("quiz.edit.ui")
  head = HTML(paste0('<textarea id="questionEdit" class="form-control question-edit">', qu$question,'</textarea>'))
  answer = quizRadioButtons(choices=qu$choices, edit=TRUE)
  btns = tagList(HTML('
  <button class="btn btn-qc btn-sm" id="btn-quiz-update">Update</button>
  '))
  ui = tagList(head,answer, btns)
  if (return.html) return(as.character(ui))
  setUI("quizEditUI", ui)
  dsetUI("quizEditUI", ui)

}

quiz.admin.send.event = function(app=getApp()) {
  restore.point("quiz.admin.send.event")
  setInnerHTML("num-send",paste0(app$glob$num.send, " replies."))
}

