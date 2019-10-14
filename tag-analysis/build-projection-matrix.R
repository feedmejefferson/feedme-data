##
## Use the Adams Apple hand picked set of food to calibrate
## a projection matrix that (hopefully) extracts 10 meaningful
## features/dimensions from the 300 dimensions coming out of
## our fast text tag vectors. This is not selecting 10 of the
## 300 dimensions, but rather 10 orthogonal projections that
## capture portions of all of the 300 dimensions based on 
## those projected dimensions capturing the most variance
## in our Adams Apple sample set. 
##
## We'll then use this projection matrix to form a consistent
## basis that we apply to all of the other foods going forward
## (until we come up with a better projection matrix).
##

library(tidyverse)
library(jsonlite)
source("./load-meta.R")
source("./json-dendogram.R")


## load metadata and filter out everything but adams apple foods
adams_apple = c("0000644","0000260","0000218","0000004","0000098","0000261","0000879","0000360","0000609","0000861","0000189","0000999","0000009","0000091","0000134","0000358","0000146","0000414","0000249","0000995","0000378","0000284","0000036","0000593","0000495","0000399","0000301","0000095","0000396","0000400","0000110","0000093","0000549","0000096","0000117","0000034","0000473","0000815","0000997","0000781")
meta = load_meta_folder("images/photos") %>% 
  filter(id %in% adams_apple)

####
#### Build the base food space matrix
####
stop_tags = read_csv("stop-tags.txt", col_names = FALSE) %>%
  rename(tag=X1) 
tag_vectors = load_tag_vectors() %>% anti_join(stop_tags)
tag_vectors = normalize(tag_vectors)
food_tags = meta %>% select(id, tag) %>% distinct_all()

## join these to our image ids and make sure none are missing
joined = food_tags %>%
  inner_join(tag_vectors) %>% ungroup()

grouped = joined %>%
  select(-tag) %>%
  group_by(id) %>%
  summarize_all(mean)

m = grouped %>% 
  ungroup()

## renormalize each of our food vectors to unit length
m = normalize(m)

# create a matrix using only the numeric vector columns
mtx = as.matrix(m %>% select(contains("X")))
# label the matrix rows with the food id
rownames(mtx)=m$id

###
### Use svd to find the projection matrix (it's basically
### the first N columns of the V decomposition). Here we're
### choosing to only maintain 10 dimensions.
###
s <- svd(mtx)
rank = 1:12
# mtx = s$u %*% diag(s$d)  %*% t(s$v)
# mtx =~ s$u[,rank] %*% diag(s$d[rank])  %*% t(s$v)[rank,]
# mtx %*% s$v = s$u %*% diag(s$d) 
# mtx %*% (projection matrix) = (projected matrix)
# thus s$v[,rank] = projection matrix!!
p = s$v[,rank]

write.table(p, file="projection-matrix.txt", row.names=FALSE, col.names=FALSE)


## run some agglomerative hierarchical clustering
## and plot the results based on the original matrix
#dists = dist(mtx, method="euclidean")
#clusters = hclust(dists, "ward.D2")
#JSON <- toLabeledJsonNodeTree(clusters)
#write(JSON, "d3/food-tree.json")





## use the projection matrix to project the food vectors onto
## a lower dimensional space, then build all three visuals
projected = mtx %*% p
rownames(projected) = rownames(mtx)

# hierarchical agglomerative clustered tree
dists = dist(projected, method="euclidean")
clusters = hclust(dists, "ward.D2")
JSON <- clusterToIndexedTree(clusters)
write(JSON, "d3/food-clusters.json")

# balanced decision tree
JSON=projectionToIndexedTree(data.frame(projected))
write(JSON, "d3/food-tree.json")

# scatter plot
projected.csv <- data.frame("image"=rownames(projected),projected)
write.csv(file="d3/food-plot.csv",x=projected.csv,row.names = FALSE)


