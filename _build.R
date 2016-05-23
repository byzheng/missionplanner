args <- commandArgs(TRUE)

token <- args[[1]]
secret <- args[[2]]
rmarkdown::render('help.Rmd')
file.remove('help.html')
rsconnect::setAccountInfo(name='byzheng', token=token, secret=secret)
rsconnect::deployApp(quiet=TRUE)
