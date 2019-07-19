library(tidyverse)
library(jsonlite)
source("./load-meta.R")

## load metadata for applicable foods
## -- focusing on fixed ones for now
meta = load_meta_folder("fixed/photos")

title_vectors = load_title_vectors()


ids = meta %>% group_by(id, title) %>% summarise() %>%
  select(id,title) 


## join these to our image ids and make sure none are missing
joined = meta %>% group_by(id, title) %>% summarise() %>%
  select(id,title) %>%
  inner_join(title_vectors) 

# create a matrix using only the numeric vector columns
mtx = as.matrix(joined %>% ungroup() %>% select(contains("X")))
# label the matrix rows with the food id
rownames(mtx)=joined$id

library(RandPro)
set.seed(3456)
p=form_matrix(300,20,FALSE)
projected = mtx %*% p


## run some agglomerative hierarchical clustering
#dists = dist(mtx, method="euclidean")
#clusters = hclust(dists, "ward.D2")
dists = dist(projected, method="euclidean")
clusters = hclust(dists, "ward.D2")


source("./json-dendogram.R")
## write out the food clusters file for the d3.js food explorer
JSON <- toLabeledJsonNodeTree(clusters)
write(JSON, "d3/food-clusters.json")



## try it with pca
## run pca on the food_meaningspace
#dvu <- svd(food_meaningspace)
#dvu$d[1:10]


#rownames(dvu$u) <- rownames(food_meaningspace)
#u <- dvu$u[,1:20]
#u.csv <- data.frame("image"=rownames(u),u)
#v <- left_join(views, v)
#write.csv(file="d3/pca-scatter.csv",x=u.csv,row.names = FALSE)

#source("./json-dendogram.R")
# repeat dimensions with higher significance
#dims = c(2,3,2,3,4:15)
#u=u[,dims]
JSON=pcaToBalancedLabeledTree(data.frame(projected))
write(JSON, "d3/food-clusters.json")
#JSON=pcaToBalancedTree(data.frame(u))
#write(JSON, "d3/tree.json")

projected.csv <- data.frame("image"=rownames(projected),projected)
#v <- left_join(views, v)
write.csv(file="d3/pca-scatter.csv",x=projected.csv,row.names = FALSE)
