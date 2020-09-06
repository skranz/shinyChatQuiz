quizRadioButtons = function (id="quiz-choices", choices, selected = NA, width = "100%",as.html=FALSE, edit=FALSE)
{
  restore.point("quizRadioButtons")


  nchoice = length(choices)
  if (!edit) {
  choices.html = paste0(
'<div class="radio" style="width: 100%">
  <label class="choice-label">
    <input type="radio" class="choice-input" name="quiz-choices" value="',1:nchoice,'">\n<span>',choices,'</span>
  </label>
</div>', collapse="\n")
  } else {
    rows = pmax(1,ceiling(nchar(choices)/65))
    choices.html = paste0(
'<div class="radio" style="width: 100%">
  <label class="choice-label-edit">
    <input type="radio" class="choice-input" name="quiz-choices" value="',1:nchoice,'">\n<span>',
    '<textarea id="choiceEdit', 1:nchoice,'" class="form-control choice-edit" rows="',rows,'">', choices,'</textarea>',       '</span>
  </label>
</div>', collapse="\n")
  }

  html = paste0(
'<div id="quiz-choices" style="width: 100%;" class="form-group shiny-input-radiogroup shiny-input-container shiny-bound-input">
  <div class="shiny-options-group">
',choices.html,'
  </div>
</div>'
  )

  if (as.html) return(html)
  return(HTML(html))
}
