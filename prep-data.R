library(readr)
files <- list.files("raw", "access_log.*", full.names = TRUE)
access_log <- NULL
for (f in files) {
  n <-read_delim(f,
                    " ", escape_double = FALSE, col_names = FALSE,
                    trim_ws = TRUE) 
  access_log <- rbind(access_log, n[, 1:10]) ## drop the extra 11th field in new dropwizard logs
}


colnames(access_log) <- c('host','ident','authuser','date','time',
'request','status','bytes','referrer',
'useragent')

## only include requests to hunger.json
access_log <- access_log[grep("hunger.json\\?searchSession",access_log$request),]

## extract query string params
m <- regexec("^.*searchSession\\=([^& ]*)&chosen\\=([^& ]*)&notChosen\\=([^& ]*)(&hour\\=([^& ]*))?.*$", access_log$request)
query.params <- regmatches(access_log$request, m)

access_log$search.session <- factor(sapply(query.params, function(l) l[2]))
access_log$chosen <- factor(sapply(query.params, function(l) l[3]))
access_log$not.chosen <- factor(sapply(query.params, function(l) l[4]))
access_log$hour <- factor(sapply(query.params, function(l) l[6]))
access_log$datetime <- as.POSIXct(strptime(paste(access_log$date, access_log$time), "[%d/%b/%Y:%H:%M:%S %z]"), tz="GMT")
access_log$host <- factor(access_log$host)
access_log$useragent <- factor(access_log$useragent)
access_log <- subset(access_log, select = c(host, datetime, useragent, search.session, chosen, not.chosen, hour))
