# shinyChatQuiz

Shiny app for online lecture support with chat and quizzes.

### Installation

The app uses several packages that are only hosted on Github or my drat archive. Run the following code for a local install for test purposes. To host the app on a server, I would recommend to build a docker image, as briefly explained further below.

```r
install.packages("shinyEvents",repos = c("https://skranz-repo.github.io/drat/",getOption("repos")))
install.packages("rmdtools",repos = c("https://skranz-repo.github.io/drat/",getOption("repos")))


install.packages("remotes")
library(remotes)
# Allow warning: See https://github.com/r-lib/remotes/issues/403
Sys.setenv(R_REMOTES_NO_ERRORS_FROM_WARNINGS="true")


install_github("skranz/shinyEventsPush")
```

### Shiny App

The folder `app` contains an example shiny app that runs the quiz chat. By default the app opens in the student view. To change to the teacher view add to the apps URL

`?role=admin`

To log in as teacher, you have to enter the admin password that you have specified in the `global.R` in the call to `quizChatApp`. The default is "test".

By default you get a system push notification if you have the teacher view open and a students sends a chat message. That allows you to see chat messages even if you are working, e.g. in RStudio to illustrate some coding. You need to allow such push messages in your browser for it to work.

### Docker

I run the app in a docker container that contains a shiny server see the docker folder for the files to build the image. You can adapt the following run command:

First build the image chatquiz using the code in the docker folder on this Github repository.

The following code runs the quiz app on port 3333. You may want to adapt the timezone argument.

```
docker run -d -p 3333:3838 --name chatquiz -e TZ=Europe/Berlin -v /path_on_your_server/shiny-server:/srv/shiny-server/ chatquiz
```

This code would also run RStudio inside the docker container on port 8888, which can be helpful for debugging purposes:

```
docker run -d -p 8888:8787 -p 3333:3838 --name chatquiz -e ROOT=TRUE -e USER=rstudio_user -e PASSWORD=your_rstudio_password -e TZ=Europe/Berlin -v /path_on_your_server/shiny-server:/srv/shiny-server/ chatquiz
```
