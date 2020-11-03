library(shinyChatQuiz)
disable.restore.points()

app = quizChatApp(title = "Chat and Quiz", lang="en", login.explain = "You can login with your own name or a pseudonym.", save.dir="data", admin.password = "test")

appReadyToRun(app)

# viewQuizChat(app,roles=c("client", "admin"))
