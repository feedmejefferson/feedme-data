tags <- read.csv("~/sandbox/jfm/feedme-data/tags.csv", header=FALSE)
colnames(tags) <- c("image","tag")
tags$tag <- factor(tolower(tags$tag))
tags$value <- c(1)
library(reshape2)
points <- dcast(tags, image ~ tag, value.var="value")
rownames(points) <-points[,1]
points <- points[-1]
points[is.na(points)] <- 0
#points <- t(points)
# remove tags that only show up once
cutoff <- 1
points = points[,colSums(points[-1,])>cutoff]
# remove "stop words" -- in this case the food tag
points = points[,colnames(points)!="food"]
# normalize the points to all be unit vectors
points = points/(rowSums(points^2)^.5)
# uncomment the following row to look at a smaller sample
samp = sample(1:nrow(points),64)
points = points[samp,]
## binary works well enough without normalization and combined with either ward clustering method
## euclidian works well as well, but needs to be normalized, in general, ward
## clustering seems to offer the most balanced trees
dists = dist(points)
clusters = hclust(dists, "ward.D2")
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

