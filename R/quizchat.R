
quizchat.example = function() {
  restore.point.options(display.restore.point = TRUE)
  library(shinyEvents)
  app = quizChatApp(lang="de", login.explain = "Sie können Ihren echten Namen oder ein Pseudonym eintragen. Beachten Sie, dass die Vorlesung aufgezeichnet wird und dabei auch Chatnachrichten zu sehen sind.", save.dir="C:/libraries/shinyChatQuiz/saved_qu")
  viewQuizChat(app,roles=c("client","admin"))
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

quizChatApp = function(title="QuizChat", admin.password=NULL, lang="en", auto.login = FALSE, login.explain="", save.dir=NULL) {
  restore.point("quizChatApp")
  app = eventsApp()
  glob = app$glob
  glob$title = title
  glob$admin.password = admin.password
  glob$auto.login = auto.login
  glob$login.explain = login.explain
  glob$save.dir = save.dir
  init.qc.globals(app, lang=lang)
  app$ui = fluidPage(title = title,
    quizchat.headers(),
    uiOutput("mainUI")
  )
  appInitHandler(function(session,..., app) {
    observe(priority = -100,x = {
      cat("\nobserve query string once")
      glob=app$glob
      glob$app.counter = glob$app.counter+1
      app$idnum = glob$app.counter

      query <- parseQueryString(session$clientData$url_search)


      if (isTRUE(query$role=="admin")) {
        if (auto.login) {
          init.admin.app.instance()
        } else {
          set.admin.login.ui()
        }
      } else {
        if (auto.login) {
          init.client.app.instance()
        } else {
          set.client.login.ui()
        }
      }
    })

  })
  app
}

init.qc.globals = function(app, n=100, push.msg=TRUE, push.past.secs=30, lang="de") {
  glob = app$glob
  glob$lang = lang

  set.default.templates()

  glob$qu.li = list()
  glob$app.counter = 0
  glob$qu.run = NULL
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
