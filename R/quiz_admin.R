
init.admin.app.instance = function(user=random.nickname(sep=" "),app=getApp()) {
  glob=app$glob

  app$is.admin = TRUE
  app$user = user
  app$initials = make.initials(app$user)
  init.chat.app.instance(app)
  init.admin.handlers()
  set.edit.quiz(app$glob$templates[[1]],update.forms = FALSE)

  show.admin.ui()
  update.app.cookie()

}




show.admin.ui = function(app=getApp()) {
  ui = tagList(
    htmlwidgets::getDependency("highchart","highcharter"),
    br(),icon(""),
    quiz.admin.outer.ui(),
    chat.ui(show.username=FALSE)
  )
  setUI("mainUI",ui)

  # Note that quizResultsUI must be initially visible
  # but can be hidden now. Otherwise highcharter plots
  # are not correctly shown
  callJS("showQuizPane","quizEdit")
}

init.admin.handlers = function(app=getApp()) {
  glob = app$glob


  buttonHandler("quiz-refresh-btn",fun=function(..., app=getApp()) {
    glob=app$glob
    glob$qu.res = glob$qu.run
    show.quiz.results()
  })
  eventHandler("qu-edit-blur",fun = quiz.edit.blur.handler)


  classEventHandler("template-li",event="click", fun = function(data, ..., app=getApp()) {
    restore.point("template-li click")
    templ.num = data$num
    set.edit.quiz(glob$templates[[templ.num]])
    callJS("showQuizPane","quizEdit")
  })

  buttonHandler("quiz-prev-btn", fun = function(..., app=getApp(), glob=app$glob) {
    restore.point("quiz-prev-btn-click")
    if (isTRUE(glob$qu.li.ind > 0)) {
      glob$qu.li.ind = max(1,glob$qu.li.ind-1)
      set.edit.quiz(glob$qu.li[[glob$qu.li.ind]])
      callJS("showQuizPane","quizEdit")
    }
  })
  buttonHandler("quiz-next-btn", fun = function(..., app=getApp(), glob=app$glob) {
    if (isTRUE(length(glob$qu.li) >0 &
               glob$qu.li.ind < length(glob$qu.li))) {
      glob$qu.li.ind = glob$qu.li.ind+1
      set.edit.quiz(glob$qu.li[[glob$qu.li.ind]])
      callJS("showQuizPane","quizEdit")
    }
  })

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

# User has edited a question
quiz.edit.blur.handler = function(value,input_id, ..., app=getApp()) {
  restore.point("quiz.edit.blur.handler")
  glob = app$glob
  qu = glob$qu.edit
  if (input_id == "questionEdit") {
    if (value == qu$question) return()
    qu$question = value
    qu$question.html = md2html(value)
  } else {
    choice.ind = as.integer(str.right.of(input_id,"choiceEdit"))
    if (choice.ind <= length(qu$choices)) {
      if (value == qu$choices[choice.ind]) return()
      qu$choices[choice.ind] = value
    } else {
      qu$choices = c(qu$choices,value)
    }
  }
  qu$client.ui = quiz.client.ui(qu)
  glob$qu.edit = qu
  quiz.set.admin.show.ui()
}
set.edit.quiz = function(qu, app=getApp(), update.forms=TRUE) {
  glob=app$glob
  glob$qu.edit = qu
  if (update.forms) {
    quiz.set.admin.show.ui()
    quiz.set.edit.ui()
  }
  #glob$quiz.runs = FALSE
}

add.to.qu.li = function(qu, app=getApp(), glob=app$glob) {
  n = length(glob$qu.li)
  if (n==0) {
    glob$qu.li[[1]] = qu
  } else {
    prev.qu = glob$qu.li[[n]]
    if (identical(prev.qu$choices,qu$choices) & identical(prev.qu$question, qu$question))
      return()
    glob$qu.li[[n+1]] = qu
  }
}

start.quiz = function(timer=NA,app=getApp()) {
  restore.point("start.quiz")
  glob = app$glob
  qu = glob$qu.edit
  if (is.null(qu)) {
    warning("Tried to start quiz even though no quiz was set.")
    return(NULL)
  }
  glob$qu.run = qu

  add.to.qu.li(qu)
  glob$qu.li.ind = length(glob$qu.li)

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
  glob$qu.res = glob$qu.run
  # Adapt admin UI
  glob$rv.stop.nonce(runif(1))
  evalJS('$("#btn-quiz-start").removeClass("invisible");
          $("#btn-quiz-stop").addClass("invisible");')
  callJS("stopQuizTimer")
  callJS("setQuizResultsPane")
  show.quiz.results()
  save.qu.res()
}

# Save stopped quiz and results
save.qu.res = function(app=getApp(), glob=app$glob) {
  restore.point("save.qu.res")
  if (is.null(glob$save.dir)) return()
  if (is.null(glob$res.qu$file_id)) {
    file_id = format(Sys.time(),"%Y-%m-%d_%H_%M_%S")
    glob$qu.res$file_id = file_id
  } else {
    file_id = glob$qu.res$file_id
  }
  try({
    saveRDS(glob$qu.res, paste0(glob$save.dir,"/qu_",file_id,".Rds"))
    saveRDS(glob$ans.df[seq_along(glob$app.counter),,drop=FALSE], paste0(glob$save.dir,"/ans_",file_id,".Rds"))
  })
}


quiz.admin.outer.ui = function(app=getApp()) {
  glob = app$glob
  quiz.runs = app$glob$quiz.runs

  templ = names(glob$templates)
  html = paste0('
<div id="quiz-outer" class="col-md-6">
  <div class="panel panel-primary">
    <div class="panel-heading">
      Quiz
      <button class="btn btn-qc btn-xs quiz-tab-btn" id="quizShowBtn"
     style="margin-left: 2em;">Show</button>
      <button class="btn btn-qc btn-xs quiz-tab-bt" id="quizEditBtn"
     style="">Edit</button>
      <button class="btn btn-qc btn-xs quiz-tab-btn" id="quizResultsBtn"
     style="">Results</button>
      <span class="pull-right">
        <button class="btn btn-qc btn-xs" id="quiz-prev-btn" style="margin-right: 4px;"><i class="fas fa-chevron-left"></i>
        <button class="btn btn-qc btn-xs" id="quiz-next-btn"><i class="fas fa-chevron-right"></i>
        </button>
      </span>
      <div class="dropdown pull-right">
        <button class="btn btn-qc btn-xs dropdown-toggle" id="quiz-templ" style="margin-right: 8px;" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">New</button>
        <ul class="dropdown-menu dropdown-menu-right" id="templates-ul">
',
  paste0('<li><a href="#" data-num = "', seq_along(templ),'" id="template-li-', seq_along(templ),'" class="template-li">',templ,'</a></li>', collapse="\n"),
'
        </ul>
      </div>

    </div>
    <div id="quiz-body" class="panel-body" style="height: 25em">
      <div id="quizShowUI" class="shiny-html-output invisible" >', quiz.set.admin.show.ui(return.html = TRUE), '
      </div>
      <div id="quizEditUI" class="shiny-html-output">', quiz.set.edit.ui(return.html = TRUE),'</div>
      <div id="quizResultsUI" class="invisible">
        <div>
        <button class="btn btn-xs" id="quiz-refresh-btn"><i class="fas fa-sync"></i></button>
        <span id="quiz-results-question" class="invisible"></span>
        </div>
        <div id="quiz-results-plot" style="width:100%; height:14em;" class="invisible"></div>
        <div id="quiz-results-table" style="width:100%; height:14em;" class="invisible"></div>
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

quiz.set.admin.show.ui = function(qu=app$glob$qu.edit, return.html=FALSE, app=getApp()) {
  restore.point("quiz.set.admin.show.ui")
  if (is.null(qu)) return(NULL)
  ui = qu$client.ui
  if (return.html) return(as.character(ui))
  setUI("quizShowUI", ui)
  dsetUI("quizShowUI", ui)
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

quiz.set.edit.ui = function(qu=app$glob$qu.edit, return.html=FALSE, app=getApp()) {
  restore.point("quiz.edit.ui")
  head = HTML(paste0('<textarea id="questionEdit" class="form-control question-edit qu-edit">', qu$question,'</textarea>'))


  # Choices

  choices = qu$choices
  rows = pmax(1,ceiling(nchar(choices)/65))
  choices.html = paste0(
    '<div class="radio" style="width: 100%">
  <label class="choice-label-edit">
    <input type="radio" class="choice-input" name="quiz-choices" value="',seq_along(choices),'">\n<span>',
    '<textarea id="choiceEdit',seq_along(choices),'" class="form-control choice-edit qu-edit" rows="',rows,'">', choices,'</textarea>',       '</span>
  </label>
</div>', collapse="\n")
  answer = HTML(paste0(
    '<div id="quiz-answers-edit" style="width: 100%;" class="form-group shiny-input-radiogroup shiny-input-container shiny-bound-input">
  <div class="shiny-options-group">
',choices.html,'
  </div>
</div>'
  ))


  btns = tagList(HTML('
  <button class="btn btn-qc btn-sm" id="btn-quiz-update">Update</button>
  '))
  btns = NULL
  ui = tagList(head,answer, btns)
  if (return.html) return(as.character(ui))
  setUI("quizEditUI", ui)
  dsetUI("quizEditUI", ui)

}

quiz.admin.send.event = function(app=getApp()) {
  restore.point("quiz.admin.send.event")
  setInnerHTML("num-send",paste0(app$glob$num.send, " replies."))
}

