set.client.login.ui = function(app=getApp(),glob=app$glob, lang=glob$lang, default.user = "") {
  restore.point("set.client.login.ui")
  if (lang=="en") {
    ui = tagList(
      textInput("userInput","Name shown in chat", default.user),
      if (!is.null(glob$login.explain)) helpText(glob$login.explain),
      checkboxInput("saveCookieCheck","Save settings as cookie for faster login",value = FALSE),
      uiOutput("loginMsg"),
      simpleButton("loginBtn","Start", form.ids = c("userInput","saveCookieCheck"))
    )
  } else if (lang=="de") {
    ui = tagList(
      textInput("userInput","Name der im Chat angezeigt wird", default.user),
      if (!is.null(glob$login.explain)) helpText(glob$login.explain),
      checkboxInput("saveCookieCheck","Speichere Einstellung per Cookie für automatisches einloggen.",value = FALSE),
      uiOutput("loginMsg"),
      simpleButton("loginBtn","Los gehts...", form.ids = c("userInput","saveCookieCheck"))
    )
  }
  ui = wellPanel(h4(glob$title), ui)
  setUI("mainUI",ui)
  buttonHandler("loginBtn", function(formValues,..., app=getApp()) {
    args = list(...)
    restore.point("loginClick")
    user = formValues$userInput
    if (nchar(trimws(user))==0) {
      setUI("loginMsg","Please enter a username")
      return()
    }

    app$perma.cookie = formValues$saveCookieCheck
    if (nchar(user)==0)
      user = random.nickname(sep=" ")
    init.client.app.instance(user=user)
  })

}

set.admin.login.ui = function(app=getApp(),glob=app$glob, lang=glob$lang) {
  restore.point("set.admin.login.ui")
  ui = tagList(
    textInput("userInput","Name shown in chat", "Teacher"),
    if (!is.null(glob$login.explain)) helpText(glob$login.explain),
    if (!is.null(glob$admin.password))
      passwordInput("adminPassword","Password"),
    checkboxInput("saveCookieCheck","Save settings as cookie for faster login",value = FALSE),
    uiOutput("loginMsg"),
    simpleButton("loginBtn","Start", form.ids = c("userInput","saveCookieCheck","adminPassword"))
  )
  ui = wellPanel(h4(glob$title), ui)
  setUI("mainUI",ui)
  buttonHandler("loginBtn", function(formValues,..., app=getApp()) {
    args = list(...)
    restore.point("loginClick")
    glob = app$glob
    user = formValues$userInput
    if (nchar(trimws(user))==0) {
      setUI("loginMsg","Please enter a username")
      return()
    }
    if (!is.null(glob$admin.password)) {
      pw = formValues$adminPassword
      if (pw != glob$admin.password) {
        setUI("loginMsg","Wrong password entered.")
        return()
      }
    }

    app$perma.cookie = formValues$saveCookieCheck
    init.admin.app.instance(user=user)
  })

}
