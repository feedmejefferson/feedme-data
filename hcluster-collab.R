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
# remove the subsession column
ratings = ratings[,-1]
points = t(ratings)

#points = points/(rowSums(points^2)^.5)
# uncomment the following row to look at a smaller sample
#points = points[1:32,]
## binary works well enough without normalization and combined with either ward clustering method
## euclidian works well as well, but needs to be normalized, in general, ward
## clustering seems to offer the most balanced trees
dists = dist(points)
clusters = hclust(dists, method="ward.D")
plot(clusters)
m=as.matrix(dists)


source("./convert-to-d3-dendrogram.R")
JSON <- HCtoJSON4(clusters)
write(JSON, "d3/clusters.json")
#points.matrix <- as.matrix(points)
#D3Dendo(JSON, file_out="d3/dendo.html")



#dvu <- svd(points.matrix)
#dvu$d[1:10]
#rownames(dvu$v) <- colnames(points.matrix)
#v <- dvu$v[,1:10]
#v <- data.frame("image"=rownames(v),"S"=c(1),"C"=c(1),"U"=c(1),v)
#write.csv(file="d3/pca-scatter.csv",x=v,row.names = FALSE)

