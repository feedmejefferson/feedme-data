library(tidyverse)
library(jsonlite)
source("./load-meta.R")
source("./json-dendogram.R")


## filter for adams apple hand selected demo foods
adams_apple = c("0000644.jpg","0000260.jpg","0000218.jpg","0000004.jpg","0000098.jpg","0000261.jpg","0000879.jpg","0000360.jpg","0000609.jpg","0000861.jpg","0000189.jpg","0000999.jpg","0000009.jpg","0000091.jpg","0000134.jpg","0000358.jpg","0000146.jpg","0000414.jpg","0000249.jpg","0000995.jpg","0000378.jpg","0000284.jpg","0000036.jpg","0000593.jpg","0000495.jpg","0000399.jpg","0000301.jpg","0000095.jpg","0000396.jpg","0000400.jpg","0000110.jpg","0000093.jpg","0000549.jpg","0000096.jpg","0000117.jpg","0000034.jpg","0000473.jpg","0000815.jpg","0000997.jpg","0000781.jpg")

## load metadata for applicable foods
## -- focusing on fixed ones for now
meta = load_meta_folder("fixed/photos")

####
#### create a title space for calculating similarity
####
#title_vectors = load_title_vectors()
#ids = meta %>% group_by(id, title) %>% summarise() %>%
#  select(id,title) 
## join these to our image ids and make sure none are missing
#joined = meta %>% group_by(id, title) %>% summarise() %>%
#  select(id,title) %>%
#  inner_join(title_vectors) 


####
#### use multiple tag spaces depending on tag type to
#### determine similarity -- give greatest significance
#### to "isTags", less weighting to contains and descriptive
####
tag_vectors = load_tag_vectors()
tag_vectors = normalize(tag_vectors)

food_tags = meta %>% select(id, tag.type, tag) %>% distinct_all()

## only use adams apple foods
food_tags = food_tags %>% filter(id %in% adams_apple)

## join these to our image ids and make sure none are missing
joined = food_tags %>%
  inner_join(tag_vectors) %>% ungroup()

grouped = joined %>%
  select(-tag) %>%
  group_by(id, tag.type) %>%
  summarize_all(mean)

m = grouped %>% 
#  filter(tag.type=="containsTags") %>% 
  filter(tag.type=="isTags") %>% 
#  filter(tag.type=="descriptiveTags") %>% 
  select(-tag.type) %>%
  ungroup()

## normalize after averaging?
m = normalize(m)

# create a matrix using only the numeric vector columns
mtx = as.matrix(m %>% select(contains("X")))
# label the matrix rows with the food id
rownames(mtx)=m$id



## run some agglomerative hierarchical clustering
dists = dist(mtx, method="euclidean")
clusters = hclust(dists, "ward.D2")


## write out the food clusters file for the d3.js food explorer
JSON <- toLabeledJsonNodeTree(clusters)
write(JSON, "d3/food-clusters.json")


## use random projection approach
library(RandPro)
set.seed(3456)
p=form_matrix(300,20,FALSE)
projected = mtx %*% p

JSON=pcaToBalancedLabeledTree(data.frame(projected))
write(JSON, "d3/food-clusters.json")


## try it with pca
## run pca on the food_meaningspace
dvu <- svd(mtx)
dvu$d[1:10]

rownames(dvu$u) <- rownames(mtx)
u <- dvu$u[,1:20]
u.csv <- data.frame("image"=rownames(u),u)
#v <- left_join(views, v)
write.csv(file="d3/pca-scatter.csv",x=u.csv,row.names = FALSE)

source("./json-dendogram.R")
# repeat dimensions with higher significance
#dims = c(2,3,2,3,4:15)
dims = 1:15
JSON=pcaToBalancedLabeledTree(data.frame(u[,dims]))
write(JSON, "d3/food-clusters.json")
#JSON=pcaToBalancedTree(data.frame(u))
#write(JSON, "d3/tree.json")

projected.csv <- data.frame("image"=rownames(projected),projected)
#v <- left_join(views, v)
write.csv(file="d3/pca-scatter.csv",x=projected.csv,row.names = FALSE)
