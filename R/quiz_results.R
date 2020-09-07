example.show.quiz.results = function() {
  yaml = "
question: |
  What is the 3th letter?
sc:
  - A and I write a much longer text, so I can see what else I could have written here......... Yea Yeh!!!
  - B
  - C*
  - D
"
  qu = makeQuiz(yaml=yaml)
  ans.df = data.frame(idnum = 1:100, choice = sample(1:4,100, replace=TRUE))
  show.quiz.results(ans.df, qu)
}

show.quiz.results = function(ans.df=glob$ans.df, qu=glob$qu.res, show.sol=FALSE, do.plot=TRUE, app=getApp(),glob=app$glob) {
  restore.point("show.quiz.results")

  choices = unlist(qu$choices)
  has.mathjax = any(has.substr(choices,"\\("))
  if (is.na(do.plot)) do.plot = !has.mathjax

  ans.df = ans.df[!is.na(ans.df$choice),]
  nchoices = length(choices)
  counts = tabulate(ans.df$choice, nchoices)
  names(counts) = choices
  shares = round(100*counts / max(1,sum(counts)))
  nans = NROW(ans.df)

  glob$results.plot = glob$results.table = NULL

  setInnerHTML("quiz-results-question", paste0(qu$question,"\n<script>if (window.MathJax) MathJax.Hub.Queue([\"Typeset\", MathJax.Hub]);</script>"))
  set.visible("#quiz-results-question")

  if (do.plot) {
    choice.labels = choices
    if (show.sol) {
      choice.labels[qu$answer.ind] = paste0("*", choice.labels[qu$answer.ind])
    }
    plot = choices.barplot(values=choices[ans.df$choice], choices, answer.ind=qu$answer.ind, choice.labels=choice.labels)
    glob$results.plot = plot
    set.visible("#quiz-results-plot")
    opts = plot$x$hc_opts
    callJS("showResultsPlot",opts)
    # show a table
  } else {
    n = length(choices)
    bg.color = rep("#fff",n)
    if (show.sol) {
      rows = seq_along(choices) == qu$answer.ind
      bg.color[rows] = "#aaf"
    }
    df = tibble(counts, paste0("(",shares,"%)"), choices)

    html = html.result.table(df,colnames=c("Number","Share","Answer",""), font.size="110%", align=c("center","center","left"),bg.color = bg.color)
    setInnerHTML("quiz-results-table", html)
    setVisible("#quiz-results-table")
    glob$results.table = html
  }
}

choices.barplot = function(values, choices=names(counts), counts=NULL,col="#ff8888", axes=FALSE, answer.ind=NULL, colors=clicker.bar.color(choices=choices,answer.ind=answer.ind),choice.labels = choices, ....) {
  restore.point("choices.barplot")

  if (is.null(counts)) {
    counts = rep(0, length(choices))
    names(counts) = choices
    cc = table(values)
    counts[names(cc)] = cc
  }
  nn_counts = counts
  names(nn_counts) = NULL
  shares = nn_counts / max(sum(nn_counts),1)

  highchart() %>%
    hc_chart(type = "column", events=list(
      redraw = JS('function () {
          //alert("The chart is being redrawn");
          MathJax.Hub.Queue(["Typeset", MathJax.Hub]);
        }'
      )
    )
    ) %>%
    hc_plotOptions(
      column=list(
        dataLabels=list(enabled=TRUE),colorByPoint = TRUE,colors=colors
      ),
      colors=colors
    ) %>%
    hc_xAxis(labels=list(useHTML=TRUE),categories = choice.labels) %>%
    hc_add_series(data = nn_counts,name = "Number of answers",showInLegend=FALSE)

}

clicker.bar.color = function(right=NULL, choices=NULL, answer.ind=NULL) {
  restore.point("clicker.bar.colors")
  if (is.null(right)) {
    right = rep(2, length(choices))
    if (length(answer.ind)>0) {
      right = seq_along(choices) == answer.ind
    }
  }
  cols = c("#ec8888", "#7cb5ec")
  cols = c("#d35400","#2980b9","#aa22cc")
  cols = c("#d35400","#2960d9","#aa42cc")

  cols = c("#d35400","#2980b9","#2980b9")
  cols[right+1]

}

html.result.table = function(df,colnames=colnames(df), bg.color="#fff", font.size=14, align=NULL) {
  restore.point("html.table")
  n = NROW(df)
  row.bgcolor = rep(bg.color,length=n)

  if (is.null(align)) align="left"
  align=rep(align, length=NCOL(df))

  head = paste0('<th class="result-table-th">',colnames,'</th>', collapse="")
  head = paste0('<tr>', head, '</tr>')

  td.class = rep("result-table-td", NROW(df))

  cols = 1:NCOL(df)
  code = paste0('"<td style=\\"text-align: ",align[[',cols,']] ,"\\" class=\\"",td.class,"\\" nowrap bgcolor=\\"",row.bgcolor,"\\">", df[[',cols,']],"</td>"', collapse=",")
  code = paste0('paste0("<tr>",',code,',"</tr>", collapse="\\n")')
  call = parse(text=code)
  main = eval(parse(text=code))

  tab = paste0('<table>\n', head, main, "\n</table>")

  th.style='font-weight: bold; margin: 3px; padding: 3px; text-align: center; border-bottom: solid;'
  td.style='font-family: Verdana,Geneva,sans-serif; margin: 0px 3px 1px 3px; padding: 1px 3px 1px 3px; text-align: center; border-bottom: solid;'

  if (!is.null(font.size)) {
    th.style = paste0(th.style, "font-size: ", font.size,";")
    td.style = paste0(td.style, "font-size: ", font.size,";")
  }

  tab = paste0("<style>",
               " table.result-table-table {	border-collapse: collapse;  display: block; overflow-x: auto;}\n",
               " td.result-table-td {", td.style,"}\n",
               " th.result-table-th {", th.style,"}\n",
               "</style>",tab
  )
  return(tab)
}

