examples.quiz = function() {
yaml = "
question: |
  What is 2*2
sc:
  - 1
  - 2
  - 3
  - 4
"
qu = makeQuiz(yaml=yaml)
}

#' Create a shiny quiz widget
#'
#' @param id the id of the quiz
#' @param qu a list that contains the quiz fields as would have
#'        been parsed by read.yaml from package YamlObjects
#' @param yaml alternatively to qu, is yaml a string that specifies the quiz
#' @param quiz.handler a function that will be called if the quiz is checked.
#'        The boolean argument solved is TRUE if the quiz was solved
#'        and otherwise FALSE
makeQuiz = function(id=paste0("quiz_",sample.int(10e10,1)),qu=NULL, yaml) {
  restore.point("clickerQuiz")

  if (is.null(qu)) {
    yaml = enc2utf8(yaml)

    qu = try(mark_utf8(parse.hashdot.yaml(yaml)), silent=TRUE)
    if (is(qu,"try-error")) {
      err = paste0("When importing quiz:\n",paste0(yaml, collapse="\n"),"\n\n",as.character(qu))
      stop(err,call. = FALSE)
    }
    qu$yaml = yaml
  }

  if (is.null(qu[["id"]])) {
    qu$id = id
  }
  qu = init.quiz(qu)
  qu
}

init.quiz = function(qu) {
  restore.point("init.quiz.qu")

  qu$choicesId = paste0("quiz-choices")
  if (!is.null(qu[["sc"]])) {
    qu$choices = qu$sc
    qu$multiple = FALSE
  } else if (!is.null(qu[["mc"]])) {
    qu$choices = qu$mc
    qu$multiple = TRUE
  }


  if (is.null(qu$choices)) stop("Only multiple and single choice quizzes are currently supported.")
  if (!is.null(qu$choices)) {
    if (!is.null(qu[["answer.ind"]])) {
      if (is.character(qu$answer.ind)) {
        qu$answer.ind = list.string.to.vector(qu$answer.ind,class="integer")
      }
      answer.ind = qu$answer.ind
    } else {
      answer.ind = which(str.ends.with(qu$choices,"*"))
      qu$choices[answer.ind] = str.remove.ends(qu$choices[answer.ind],right=1)
    }

    if (is.null(qu$multiple)) {
      qu$multiple = length(answer.ind) != 1
    }
    qu$answer.ind = answer.ind
    qu$answer = unlist(qu$choices[answer.ind])
    names(qu$choices) =NULL
    if (qu$multiple) {
      qu$type = "mc"
    } else {
      qu$type = "sc"
    }
  }
  qu$question.html = md2html(qu$question)
  #qu$ui = quiz.ui(qu)
  qu$client.ui = quiz.client.ui(qu)
  qu
}

quiz.ui = function(qu, solution=FALSE) {
  restore.point("quiz.ui")
  head = list(
    HTML(qu$question.html)
  )
  if (solution) {
    if (qu$type=="mc") {
      answer = checkboxGroupInput(qu$choicesId, label=NULL,qu$choices,selected = qu$answer)
    } else if (qu$type=="sc") {
      answer = radioButtons(qu$choicesId, label=NULL,qu$choices, selected=qu$answer)
    }
  } else {
    if (qu$type=="mc") {
      answer = checkboxGroupInput(qu$choicesId, label=NULL,qu$choices)
    } else if (qu$type=="sc") {
      answer = radioButtons(qu$choicesId, label=NULL,qu$choices, selected=NA)
    }
  }

  withMathJax(div(class="quiz_div",head, answer,uiOutput(qu$resultId)))
}

quiz.md = function(qu, solution=FALSE) {
  restore.point("quiz.md")
  head = paste0("\nQuiz: ",qu$question,"\n")
  if (solution) {
    if (qu$type=="mc" | qu$type=="sc") {
      ans = qu$choices
      mark = rep("[ ]", length(ans))
      mark[ans %in% qu$answer] =  "[x]"
      answer = paste0("- ", ans, " ", mark,"\n", collapse="\n")
    }
  } else {
    if (qu$type=="mc" | qu$type=="sc") {
      ans = qu$choices
      answer = paste0("- ", ans, "[   ]\n", collapse="\n")
    }
  }
  paste0(head,"\n", answer)
}


quiz.client.ui = function(qu) {
  restore.point("quiz.client.ui")
  head = list(
    HTML(qu$question.html)
  )
  if (qu$type=="sc") {
    answer = quizRadioButtons(choices=qu$choices)
  } else {
    stop("Checkbox quizzes (mc) or other forms are not yet supported.")
  }
  list(head,answer)

  pli = list(head,answer)
  pli=  tagList(pli,uiOutput("quiz-msgUI"))
  withMathJax(pli)
}
