set.visible = function(sel) {
  callJS("setVisible",sel)
}
set.invisible = function(sel) {
  callJS("setInvisible",sel)
}


has.substr = function(str, pattern) {
  grepl(pattern, str, fixed=TRUE)
}


make.initials = function(user) {
  if (has.substr(user," ")) {
    initials = toupper(substring(paste0(substring(strsplit(user, " ")[[1]][1:2],1,1), collapse=""),1,2))

  } else if (has.substr(user, "_")) {
    initials = toupper(substring(paste0(substring(strsplit(user, "_")[[1]][1:2],1,1), collapse=""),1,2))
  } else {
    initials = toupper(substring(user,1,2))
  }
  initials
}
