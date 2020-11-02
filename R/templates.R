templates.examples = function() {
  file = system.file("templates/templates-de.yaml",package = "shinyChatQuiz")
}


set.default.templates = function(app=getApp()) {
  glob = app$glob
  lang = glob$lang
  if (!is.null(glob$template.file)) {
    file = glob$template.file
  } else {
    file = system.file(paste0("templates/templates-",lang,".yaml"),package = "shinyChatQuiz")
  }
  glob$templates = load.template.yaml(file)
}

load.template.yaml = function(file) {
  qu.li = yaml.load_file(file)
  templates = lapply(qu.li, function(qu) {
    qu = makeQuiz(qu=qu)
  })
  templates
}
