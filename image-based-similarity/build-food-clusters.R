
points <- read.csv("~/sandbox/jfm/feedme-data/image-based-similarity/food-vectors.csv")
colnames(points) <- gsub("X", "", colnames(points))
points <- as.matrix(points)
points <- t(points)

# uncomment the following row to look at a smaller sample
#samp = sample(1:nrow(points),64)
#points = points[samp,]
## binary works well enough without normalization and combined with either ward clustering method
## euclidian works well as well, but needs to be normalized, in general, ward
## clustering seems to offer the most balanced trees
dists = dist(points)
clusters = hclust(dists, "ward.D2")
#plot(clusters)
#m=as.matrix(dists)


source("../tag-analysis/json-dendogram.R")
## write out the food clusters file for the d3.js food explorer
JSON <- toLabeledJsonNodeTree(clusters)
write(JSON, "d3/food-clusters.json")
## write out the simplified food tree for crystal bowl
#JSON <- toJsonNodeTree(clusters)
#write(JSON, "d3/tree.json")
points.matrix <- t(points)
#D3Dendo(JSON, file_out="d3/dendo.html")



dvu <- svd(points.matrix)
dvu$d[1:10]
rownames(dvu$v) <- colnames(points.matrix)
v <- dvu$v[,1:10]
v <- data.frame("image"=rownames(v),"S"=c(1),"C"=c(1),"U"=c(1),v)
write.csv(file="d3/pca-scatter.csv",x=v,row.names = FALSE)

