source("prep-data.R")


library(dplyr)
data <- select(access_log, search.session, datetime, chosen, not.chosen) %>% arrange(., search.session, datetime)

clicks <- select(data, image = chosen)  %>% group_by(., image) %>% summarize(C=n())
not.clicks <- select(data, image = not.chosen) %>% group_by(., image) %>% summarize(U=n())
views <- full_join(clicks, not.clicks)
## replace missing values from full outer join with 0
views[is.na(views)] <- 0
views$S <- views$C + views$U
views$CTR <- views$C/views$S
live.images <- read.table("foodlist.txt")
colnames(live.images) <- c("image")
views <- left_join(live.images, views)
## ideally we'd only like to present comparisons for foods with similar popularity
## we'll use click through rate as a general measure of popularity and stratify foods
## by their CTR percentile into q discrete quantiles
q <- 10
#views$Q <- cut(views$CTR, breaks=quantile(views$CTR, probs=((0:q)/q)), labels=1:q, include.lowest = TRUE)
views <- views %>% mutate(Q=ntile(CTR, q))

stratified.images = split(views$image,views$Q)

library(jsonlite)
filename = "stratified.ts"
write("export const STRATIFIED: string[][] = ", filename)
write(toJSON(unname(stratified.images), pretty=TRUE), filename, append=TRUE)
write(";", filename, append=TRUE)
