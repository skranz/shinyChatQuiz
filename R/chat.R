
chat.example = function() {
  restore.point.options(display.restore.point = TRUE)
  library(shinyEvents)

  app = eventsApp()
  app$glob$app.counter = 0
  init.chat.globals(app)
  app$ui = fluidPage(
    quizchat.headers(),
    push.js.headers(),
    p("Chat Example"),
    chat.ui(),
    simpleButton("testBtn","Add Random Text")
  )
  eventHandler("chatSendEvent",fun =  function(value, ..., app=getApp()) {
    add.chat.entry(msg=value,app=app)
  })
  buttonHandler("testBtn", function(...){
    add.chat.entry(msg="This is just a long, or not so long test message.")
  })
  appInitHandler(function(..., app) {
    init.chat.app.instance(app)
  })
  viewApp(app)
}

init.chat.app.instance = function(app) {
  glob = app$glob
  app$msg.counter = 0
  color = glob$colors[ (app$idnum-1 %% length(glob$colors))+1 ]
  app$msg.entry = c(idnum=as.character(app$idnum), msg="", user=app$user, initials=app$initials,time="", color=color)

  app$push.msg = glob$push.msg
  app$push.past.secs = glob$push.past.secs

  observeEvent(glob$rv.msg.counter(), {
    insert.newest.chat.entries()
  })
}


initials.colors = function() {
  #library(RColorBrewer)
  #glueformula::varnames_snippet(c(brewer.pal(12,"Set3"),brewer.pal(8,"Accent"),brewer.pal(9,"Pastel1"), brewer.pal(8,"Pastel2")))

  c("#8DD3C7", "#FFFFB3", "#BEBADA", "#FB8072", "#80B1D3", "#FDB462", "#B3DE69", "#FCCDE5", "#D9D9D9", "#BC80BD", "#CCEBC5", "#FFED6F", "#7FC97F", "#BEAED4", "#FDC086", "#FFFF99", "#386CB0", "#F0027F", "#BF5B17", "#666666", "#FBB4AE", "#B3CDE3", "#CCEBC5", "#DECBE4", "#FED9A6", "#FFFFCC", "#E5D8BD", "#FDDAEC", "#F2F2F2", "#B3E2CD", "#FDCDAC", "#CBD5E8", "#F4CAE4", "#E6F5C9", "#FFF2AE", "#F1E2CC", "#CCCCCC")
}

chat.ui.alternative = function() {
  html = '
<div class="col-md-6">
  Chat
  <div id="chat-body" class="chat-body-style" style="height: 20em;">
    <ul id="chat-ul" class="chat">
    </ul>
  </div>
  <div class="input-group">
    <input id="chat-input" type="text" class="form-control input-sm" placeholder="Type your message here..." />
    <span class="input-group-btn">
        <button class="btn btn-qc btn-sm" id="btn-chat-send">
            Send</button>
    </span>
  </div>
</div>
'
  HTML(html)
}


chat.ui = function() {
   html = '<div id="chat-outer" class="col-md-5">
    <div class="panel panel-primary">
        <div class="panel-heading">

            <span>
              Chat
              <button class="btn btn-qc btn-xs" id="btn-raise-hand"
       style="margin-left: 2em;">Raise Hand</button>
              <button class="btn btn-qc btn-xs" id="btn-lower-hand"
       style="margin-left: 5px; margin-right: 5px;">Lower Hand</button>
            <span>

        </div>
        <div id="chat-body" class="panel-body" style="height: 20em">
            <ul id="chat-ul" class="chat">
            </ul>
        </div>
        <div class="panel-footer">
            <div class="input-group">
                <input id="chat-input" type="text" class="form-control input-sm" placeholder="Type your message here..." />
                <span class="input-group-btn">
                    <button class="btn btn-qc btn-sm" id="btn-chat-send">
                        Send</button>
                </span>
            </div>
        </div>
    </div>
</div>'

   HTML(html)
}

add.raise.hand.entry = function(...,app=getApp(), glob=app$glob) {
  if (glob$lang == "de") {
    add.chat.entry(paste0(app$user, " hebt Hand."))
  } else {
    add.chat.entry(paste0(app$user, " raises hand."))
  }
}
add.lower.hand.entry = function(...,app=getApp(), glob=app$glob) {
  if (glob$lang == "de") {
    add.chat.entry(paste0(app$user, " senkt Hand wieder."))
  } else {
    add.chat.entry(paste0(app$user, " lowers hand again."))
  }
}


add.chat.entry = function(msg="message", app=getApp()) {
  restore.point("add.chat.entry")
  msg = htmlEscape(msg)
  app$msg.entry["msg"] = msg
  time = Sys.time()
  app$msg.entry["time"] = format(time,"%H:%M")

  glob = app$glob
  row = glob$msg.counter+1

  # Possibly enlarge msg.mat
  n = NROW(glob$msg.mat)
  if (row+1 > n) {
    empty.mat = matrix("",nrow=n, ncol=6)
    colnames(empty.mat) = c("idnum", "msg","user", "initials","time", "color")
    glob$msg.mat = rbind(glob$msg.mat, emtpy.mat)
    glob$msg.time = c(glob$msg.time, rep(0L, n))
  }
  glob$msg.mat[row,] = app$msg.entry
  glob$msg.time[row] = time
  glob$msg.counter = glob$msg.counter+1
  glob$rv.msg.counter(glob$msg.counter)
}

insert.newest.chat.entries = function(app=getApp()) {
  restore.point("insert.newest.chat.entries")

  glob = app$glob
  if (app$msg.counter >= glob$msg.counter)
    return()
  rows = (app$msg.counter+1):glob$msg.counter
  restore.point("insert.newest.chat.entries2")

  for (row in rows) {
    callJS("insertChat", .args=as.list(glob$msg.mat[row,-1]))
  }

  # push new messages that are not older than app$push.past.secs
  if (app$push.msg) {
    time = as.numeric(Sys.time())
    past.secs = time-glob$msg.time[rows]
    use = which(past.secs <= app$push.past.secs)
    restore.point("push.messages...")
    if (length(use)>0) {
      push.message(paste0(glob$msg.mat[rows[use],"initials"],": ", glob$msg.mat[rows[use],"msg"],collapse="\n---\n"))
    }
  }
  app$msg.counter = glob$msg.counter
}


insert.chat.entry = function(msg="message", user="user",initials="U", time=format(Sys.time(),"%H:%M"), color="55C1E7") {
  restore.point("insert.chat")
  callJS("insertChat", .args=list(msg=msg, user=user, initials=initials, time=time, color=color))
}


