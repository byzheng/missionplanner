args <- commandArgs(TRUE)

token <- args[[1]]
secret <- args[[2]]
rsconnect::setAccountInfo(name='byzheng', token=token, secret=secret)
rsconnect::deployApp(quiet=TRUE)
