
init.client.app.instance = function(app=getApp()) {

  glob=app$glob
  glob$app.counter = glob$app.counter+1
  app$idnum = glob$app.counter
  app$user = random.nickname(sep=" ")
  app$initials = make.initials(app$user)

  init.chat.app.instance(app)

  show.client.ui()

  observeEvent(glob$rv.start.nonce(), {
    nonce = glob$rv.start.nonce()
    restore.point("client.observe.quiz.start")
    if (nonce != 0) {
      client.quiz.start()
    }
  })
  observeEvent(glob$rv.timer.change.nonce(), {
    nonce = glob$rv.timer.change.nonce()
    if (nonce != 0) {
      set.client.quiz.timer()
    }
  })

  observeEvent(glob$rv.stop.nonce(), {
    nonce = glob$rv.stop.nonce()
    if (nonce != 0) {
      show.client.quiz.stop()
    }
  })
  eventHandler("quizSendEvent",fun =  function(value, ..., app=getApp()) {
    send.client.quiz.answer(value,app=app)
  })
}

client.quiz.start = function(app=getApp()) {
  qu = app$glob$cur.qu
  if (!is.null(qu)) {
    setUI("quizUI", qu$client.ui)
    evalJS('$("#btn-quiz-send").removeClass("invisible");')
  }
  setUI("quiz-msgUI","")
  set.client.quiz.timer()
}

set.client.quiz.timer = function(timer = glob$timer, app=getApp(), glob=app$glob) {
  if (is.na(timer)) {
    setInnerHTML("quiz-timer","")
  } else {
    callJS("startQuizCountdown", timer)
  }
}

stop.client.quiz.timer = function(timer = glob$timer, app=getApp(), glob=app$glob) {
  callJS("stopQuizTimer")
}


show.client.quiz.stop = function(app=getApp()) {
  restore.point("show.client.quiz.stop")
  evalJS('$("#btn-quiz-send").addClass("invisible");')
  setUI("quiz-msgUI", HTML(paste0("The quiz has stopped.")))
  stop.client.quiz.timer()
}

show.client.quiz.send = function(choice, app=getApp()) {
  restore.point("show.client.quiz.send")
  setUI("quiz-msgUI", HTML(paste0("You send answer no. ", choice,". You can update it until the quiz stops.")))
}


show.client.ui = function(app=getApp()) {
  ui = tagList(
    br(),
    quiz.client.outer.ui(),
    chat.ui()
  )
  setUI("mainUI",ui)
}


send.client.quiz.answer = function(value, idnum=app$idnum, app=getApp()) {
  restore.point("send.client.quiz.answer")
  choice = as.integer(value)
  glob=app$glob
  idnum = app$idnum
  adapt.glob.ans.df(idnum)

  resend = !is.na(glob$ans.df[idnum,"choice"])
  glob$ans.df[idnum,"choice"] = choice
  if (!resend) {
    glob$num.send = glob$num.send+1
  } else {
    glob$num.resend = glob$num.resend+1
  }
  glob$rv.send.nonce(runif(1))
  show.client.quiz.send(choice)
}

quiz.client.outer.ui = function() {
  html = '
<div id="quiz-outer" class="col-md-6">
  <div class="panel panel-primary">
    <div class="panel-heading">
        Quiz  <span style="padding-left: 1em" id="quiz-time"></span>
    </div>
    <div id="quiz-body" class="panel-body" style="height: 24em">
      <div id="quizUI" class="shiny-html-output"></div>
      <button class="btn btn-qc btn-sm invisible" id="btn-quiz-send">Send</button>
    </div>
  </div>
</div>'

  HTML(html)
}