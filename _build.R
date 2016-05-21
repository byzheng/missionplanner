args <- commandArgs(TRUE)

token <- args[[1]]
secret <- args[[2]]

rsconnect::setAccountInfo(name='bzheng', token=token, secret=secret)
