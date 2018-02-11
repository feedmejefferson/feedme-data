source("prep-data.R")


library(dplyr)
data <- select(access_log, search.session, datetime, chosen, not.chosen) %>% arrange(., search.session, datetime)

clicks <- select(data, image = chosen)  %>% group_by(., image) %>% summarize(C=n())
not.clicks <- select(data, image = not.chosen) %>% group_by(., image) %>% summarize(U=n())
views <- full_join(clicks, not.clicks)
views$S <- views$C + views$U

bucket.size <- 60 ## sixty second/one minute buckets
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

dvu <- svd(ratings.matrix)
dvu$d[1:10]

rownames(dvu$v) <- colnames(ratings.matrix)
v <- dvu$v[,1:10]
v <- data.frame("image"=rownames(v),v)
v <- left_join(views, v)
write.csv(file="d3/pca-scatter.csv",x=v,row.names = FALSE)

