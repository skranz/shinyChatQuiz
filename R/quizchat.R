
quizchat.example = function() {
  restore.point.options(display.restore.point = TRUE)
  library(shinyEvents)
  yaml = "
question: |
  What is the 3rd letter?
sc:
  - A and I write a much longer text, so I can see what else I could have written here......... Yea Yeh!!!
  - B
  - C*
  - D
"
  app = quizChatApp(quiz.yaml = yaml)
  viewQuizChat(app,roles=c("client", "admin"))
}

viewQuizChat = function(app, roles=c("client","admin")) {
  launch.admin.client = function(appUrl) {
    restore.point("launch.admin.client")
    urls = c(admin=paste0(appUrl,"?role=admin"), client=appUrl)
    for (role in roles) {
      utils::browseURL(urls[role])
    }
  }
  viewApp(app,launch.browser = launch.admin.client)
}

quizChatApp = function(title="QuizChat", admin.password, quiz.yaml=NULL, lang="de") {
  restore.point("quizChatApp")
  app = eventsApp()
  glob = app$glob
  init.qc.globals(app, lang=lang)
  if (!is.null(quiz.yaml)) {
    qu = makeQuiz(yaml=quiz.yaml)
    set.quiz(qu)
  } else {
    qu = NULL
  }
  app$ui = fluidPage(title = title,
    quizchat.headers(),
    uiOutput("mainUI")
  )
  appInitHandler(function(session,..., app) {
    observe(priority = -100,x = {
      cat("\nobserve query string once")
      query <- parseQueryString(session$clientData$url_search)
      if (isTRUE(query$role=="admin")) {
        init.admin.app.instance()

        # # For testing purposes
        # glob = app$glob
        # start.quiz()
        # send.client.quiz.answer(1,idnum=1)
        # stop.quiz()
      } else {
        init.client.app.instance()
      }
      insert.newest.chat.entries()
    })

  })
  app
}

init.qc.globals = function(app, n=100, push.msg=TRUE, push.past.secs=30, lang="de") {
  glob = app$glob
  glob$lang = lang
  glob$app.counter = 0
  glob$cur.qu = NULL
  glob$num.send = glob$num.resend = 0

  glob$quiz.runs = FALSE
  glob$push.msg = push.msg
  glob$push.past.secs = push.past.secs
  glob$colors = initials.colors()

  glob$msg.counter = 0
  glob$rv.msg.counter <- reactiveVal(0)
  glob$rv.send.nonce <- reactiveVal(0)
  glob$rv.start.nonce <- reactiveVal(0)
  glob$rv.stop.nonce <- reactiveVal(0)
  glob$rv.timer.change.nonce <- reactiveVal(0)

  glob$msg.time = rep(0L,n)
  glob$msg.mat = matrix("",nrow=n, ncol=6)

  colnames(glob$msg.mat) = c("idnum", "msg","user", "initials","time", "color")
  eventHandler("chatSendEvent",fun =  function(value, ..., app=getApp()) {
    add.chat.entry(msg=value,app=app)
  })
  buttonHandler("btn-raise-hand",add.raise.hand.entry)
  buttonHandler("btn-lower-hand",add.lower.hand.entry)

}

adapt.glob.ans.df = function(idnum, app=getApp()) {
  glob = app$glob
  if (NROW(glob$ans.df < idnum)) {
    extra = data.frame(idnum=(NROW(glob$ans.df)+1):(2*idnum), choice = NA_integer_)
    glob$ans.df = rbind(glob$ans.df, extra)
  }
}



#' Add push.js.headers. Add this call to your ui
quizchat.headers = function() {

  dir = system.file("www", package="shinyChatQuiz")
  addResourcePath("shinyChatQuiz",dir)
  tagList(
    htmlwidgets::getDependency("highchart","highcharter"),
    push.js.headers(),
    tags$link(href="shinyChatQuiz/chat.css", rel="stylesheet"),
    tags$script(src="shinyChatQuiz/chat.js")
  )
}



