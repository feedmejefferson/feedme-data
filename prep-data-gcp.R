library(readr)
## This script relies on the logs from google cloud platform first being
## preprocessed and aggregated into one file. The following script removes
## all of the json wrapper from the original log messages and writes all of
## the contents from hourly batches into a single file:
# cat */*/*/*.json |\
# grep 'severity":"INFO' |\
# sed 's/^.*textPayload":"//;s/","timestamp":.*$//;s~\\"~"~g;' >aggregated_logs

access_log <-read_delim("gcp/aggregated_logs",
                    " ", escape_double = FALSE, col_names = FALSE,
                    trim_ws = TRUE) 


colnames(access_log) <- c('host','search.session','request','useragent','date')

## only include requests to hunger.json
#access_log <- access_log[grep("hunger.json\\?searchSession",access_log$request),]

## extract query string params
m <- regexec("^.*&chosen\\=([^& ]*)&notChosen\\=([^& ]*)(&hour\\=([^& ]*))?.*$", access_log$request)
query.params <- regmatches(access_log$request, m)

access_log$chosen <- factor(sapply(query.params, function(l) l[2]))
access_log$not.chosen <- factor(sapply(query.params, function(l) l[3]))
access_log$hour <- factor(sapply(query.params, function(l) l[5]))
access_log$datetime <- as.POSIXct(access_log$date/1000, origin="1970-01-01")
access_log$host <- factor(access_log$host)
access_log$useragent <- factor(access_log$useragent)
access_log <- subset(access_log, select = c(host, datetime, useragent, search.session, chosen, not.chosen, hour))
