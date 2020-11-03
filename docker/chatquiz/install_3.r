# install required R packages
 
library(methods)
  
path = .libPaths()[1]
glob.overwrite = TRUE
path = "/usr/local/lib/R/site-library"

success = failed = NULL

from.cran = function(pkg, lib = path, overwrite = glob.overwrite,...) {
  if (!overwrite) {
    if (require(pkg,character.only = TRUE)) {
      cat("\npackage ",pkg," already exists.")
      return()
    }
  }
  res = try(install.packages(pkg, lib=lib,...))
  if (require(pkg,character.only = TRUE)) {
    success <<- c(success,pkg)
  } else {
    failed <<- c(failed,pkg)
  }
}

from.github = function(pkg, lib = path, ref="master", overwrite = glob.overwrite,upgrade_dependencies = FALSE,...) {
  repo = pkg
  pkg = strsplit(pkg,"/",fixed=TRUE)[[1]]
  pkg = pkg[length(pkg)]

  if (!overwrite) {
    if (require(pkg,character.only = TRUE)) {
      cat("\npackage ",pkg," already exists.")
      return()
    }
  }

  temp <- tempfile(fileext=".zip")
  url = paste0("https://github.com/",repo,"/archive/master.zip")
  #https://github.com/skranz/RTutor/archive/master.zip
  download.file(url,temp)

  library(devtools)
  library(withr)
  res = try(
  with_libpaths(new = path,
    install_local(temp, upgrade="never")
    #install_github(repo,ref = ref,upgrade="never",...)
    #pak::pkg_install(repo)
  ))
  if (require(pkg,character.only = TRUE)) {
    success <<- c(success,pkg)
  } else {
    failed <<- c(failed,pkg)
  }

}

from.github(lib=path,"skranz/shinyChatQuiz",ref = "master")


cat("\n\nFailed installations:\n")
print(failed)

cat("\n\nSuccessfully installed:\n")
print(success) 





















