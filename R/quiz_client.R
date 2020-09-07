
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
  qu = app$glob$qu.run


  if (!is.null(qu)) {
    dsetUI("quizUI", qu$client.ui)
    set.invisible("#no-quiz-runs-msg")
    set.visible("#quiz-outer")
    #evalJS('$("#btn-quiz-send").removeClass("invisible");')
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
  #evalJS('$("#btn-quiz-send").addClass("invisible");')
  #setUI("quiz-msgUI", HTML(paste0("The quiz has stopped.")))
  stop.client.quiz.timer()
  set.visible("#no-quiz-runs-msg")
  set.invisible("#quiz-outer")
}

show.client.quiz.send = function(choice, app=getApp()) {
  restore.point("show.client.quiz.send")
  if (app$glob$lang == "de") {
    dsetUI("quiz-msgUI", HTML(paste0("Danke für deine Antwort. Bis das Quiz stoppt kannst du sie auch noch ändern.")))
  } else {
    dsetUI("quiz-msgUI", HTML(paste0("Thanks for your answer. Changes are possible until the the quiz stops.")))
  }
}


show.client.ui = function(app=getApp()) {
  ui = tagList(
    br(),
    withMathJax(quiz.client.outer.ui()),
    chat.ui()
  )
  setUI("mainUI",ui)
}


send.client.quiz.answer = function(value, idnum=app$idnum, app=getApp()) {
  restore.point("send.client.quiz.answer")
  choice = as.integer(value)
  if (is.na(choice)) {
    if (app$glob$lang == "de") {
      dsetUI("quiz-msgUI", HTML(paste0("Bitte wähle eine Antwort.")))
    } else {
      dsetUI("quiz-msgUI", HTML(paste0("Please choose an answer.")))
    }
    return()
  }

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

quiz.client.outer.ui = function(app=getApp()) {
  quiz.runs = app$glob$quiz.runs
  qu = app$glob$qu.run
  html = paste0('
<div id="no-quiz-runs-msg" class="row ', if (quiz.runs) 'invisible','">
  <div class="col-md-5">
    <center></center>
  </div>
</div>
<div id="quiz-outer" class="col-md-5 ', if (!quiz.runs) 'invisible','">
  <div class="panel panel-primary">
    <div class="panel-heading">
        Quiz  <span style="padding-left: 1em" id="quiz-time"></span>
    </div>
    <div id="quiz-body" class="panel-body" style="height: 24em">
      <div id="quizUI" class="shiny-html-output">', if (quiz.runs) as.character(qu$client.ui), '</div>
      <button class="btn btn-qc btn-sm" id="btn-quiz-send">Send</button>
    </div>
  </div>
</div>')

  HTML(html)
}
