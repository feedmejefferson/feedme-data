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

bucket.size <- 120 ##  two minute buckets
data$subsession <- paste(data$search.session, as.integer(as.integer(data$datetime)/bucket.size), sep=":")


sdata <- split(data, data$subsession)
sdata <- lapply(sdata,function (x) {
  x$decision.time <- as.integer(x$datetime - x$datetime[c(NA,1:nrow(x)-1)]);
  mean <- mean(x$decision.time,na.rm=TRUE)
  mean <- if(is.na(mean)) 4 else mean
  x$decision.time[is.na(x$decision.time)] <- mean
  sd <- sd(x$decision.time,na.rm=TRUE)
  collar <- if(is.na(sd)) .5 else max(sd/2,.6)
  x$weight <- cut(x$decision.time,c(-Inf,mean-collar,mean+collar,Inf),labels=c(2,1,.5))
  x;
})
data <- do.call("rbind", sdata)

library(reshape2)
melted <- melt(data, 
               id.vars=c("subsession", "weight"),
               measure.vars=c("chosen", "not.chosen"))

## assign chosen and not chosen positive and negative weightings
map <- c(-1,1)
names(map) <- c("not.chosen","chosen")
melted$weight <- map[as.character(melted$variable)] * as.numeric(as.character(melted$weight))

ratings <- dcast(melted, subsession ~ value, fun.aggregate = sum, value.var="weight")
ratings.matrix <- as.matrix(ratings[,-1])
rownames(ratings.matrix) <- ratings[,1]

## run PCA to map foods onto best food space
dvu <- svd(ratings.matrix)

## grab the top d dimensions for all food items
d <- 10
## grab the top and bottom N items for each dimension
n <- 5
rownames(dvu$v) <- colnames(ratings.matrix)
v <- dvu$v[,1:d]
v <- left_join(views[c("image", "Q")], data.frame("image"=rownames(v),v))
v <- split(v,v$Q)

## write out a yaml file with the top and bottom N food items from the D most significant dimensions
## skip the first two columns in every split dataframe
write("stratified-cafeteria:", "test.yaml",append=FALSE)
for(dimension in 1:d) {
  for(table.split in v) {  
    write(paste(c("  dimension-", dimension,"-quantile-", table.split$Q[1],":"),collapse = ""), "test.yaml",append=TRUE)
    column=dimension+2
    l <- dim(table.split)[1]
    sorted.index <- order(table.split[,column])
    topN <- table.split$image[sorted.index][1:n]
    write(paste(c("    top: ['",paste(topN, collapse="', '"),"']"),collapse = ""), "test.yaml",append=TRUE)
    bottomN <- table.split$image[sorted.index][(l-n+1):l]
    write(paste(c("    bottom: ['",paste(bottomN, collapse="', '"),"']"),collapse = ""), "test.yaml",append=TRUE)
  }
}

