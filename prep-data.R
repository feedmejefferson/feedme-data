library(readr)
access_log <- read_delim("~/sandbox/jfm/feedme-data/access_log",
" ", escape_double = FALSE, col_names = FALSE,
trim_ws = TRUE)

colnames(access_log) <- c('host','ident','authuser','date','time',
'request','status','bytes','referrer',
'useragent')

## only include requests to hunger.json
access_log <- access_log[grep("hunger.json",access_log$request),]

## extract query string params
m <- regexec("^.*searchSession\\=([^& ]*)&chosen\\=([^& ]*)&notChosen\\=([^& ]*).*$", access_log$request)
query.params <- regmatches(access_log$request, m)

access_log$search.session <- sapply(query.params, function(l) l[2])
access_log$chosen <- factor(sapply(query.params, function(l) l[3]))
access_log$not.chosen <- factor(sapply(query.params, function(l) l[4]))

