library(tidyverse)
library(jsonlite)
source("./load-meta.R")
source("./json-dendogram.R")

## load metadata for applicable foods
## -- focusing on fixed ones for now
meta = load_moderator_foods("from-import/foods")

## build the index
tagFoods = meta %>% select(id, tag) %>% 
  distinct_all() %>%
  mutate(foods=id,id=tag) %>%
  select(id, foods) %>%
  arrange(id, foods) %>% 
  chop(foods) 
## for now I'm writing it out, but in reality we just want
## to reconcile it with the exported one. The orders will
## be different because newly tagged foods will show up at
## the end of the list, but the sets of foods should be
## identical for each tag. 
write(jsonlite::toJSON(tagFoods), "to-export/tagFoods.json")


####
#### use multiple tag spaces depending on tag type to
#### determine similarity -- give greatest significance
#### to "isTags", less weighting to contains and descriptive
####
dictionary = load_tag_vectors()
tags = meta %>% 
  select(tag) %>% 
  group_by(tag) %>% 
  summarize(count=n())

tagspace <- tags %>% left_join(dictionary)
tagspace <- normalize0(tagspace)
tagmtx = as.matrix(tagspace %>% select(contains("X")))
rownames(tagmtx) <- tagspace$tag
p = as.matrix(read.table("projection-matrix-alt.txt"))
ptags = tagmtx %*% p
colnames(ptags)=paste("X",1:12, sep="") ## TODO: fix the javascript to be more forgiving
#ptags = normalize0(data.frame(ptags))
pdict = data.frame("tag"=rownames(ptags),ptags)


dtags <- dist(ptags)
tagclusters <- hclust(dtags)

# word tree
tagvalues <- tagspace %>% 
  mutate(value=tag, size=count) %>%
  select(value, size) 
JSON <- clusterToIndexedTree(tagclusters, tagvalues)
write(JSON, "data-explorer/word-tree.json")

# scatter plot
projected.csv <- data.frame("image"=rownames(ptags),ptags)
write.csv(file="data-explorer/word-scatter.csv",x=projected.csv,row.names = FALSE)

tag.distmtx = as.matrix(dtags)
#nn = function(z){names(z)[order(z)[2:6]]} ## moved to load-meta
tag.neighbors = t(apply(tag.distmtx,2,nn))

tag_occurences = meta %>% 
  group_by(tag, tag.type) %>%
  summarize(n=n()) %>%
  spread(key=tag.type, value=n, fill=0)

tags.json = tibble(id=rownames(ptags), dims=as.matrix(ptags), neighbors=tag.neighbors)
j = tags.json %>% left_join(tag_occurences, by=c("id"="tag"))
write(jsonlite::toJSON(j), "to-export/tagStats.json")

food_tags = meta %>% select(id, tag, edited, updated) %>% distinct_all()

## join these to our image ids and make sure none are missing
joined = food_tags %>%
  left_join(pdict) %>% ungroup()

grouped = joined %>%
  select(-tag) %>%
  #  group_by(id, tag.type) %>%
  group_by(id, edited, updated) %>%
  summarize_all(mean)

m = grouped %>% 
  ungroup()

## normalize after averaging? Ditch the first "foodiness" dimension? 
#mn = m %>% select(-c("X1"))  
#mn = normalize(mn)

# create a matrix using only the numeric vector columns
mtx = as.matrix(m %>% select(contains("X")))
# mtx = as.matrix(mn %>% select(contains("X"))) # using normalized matrix

# label the matrix rows with the food id
# TODO: create a better function for jumping between tidy and matrix forms
rownames(mtx)=m$id

## Build all the snazzy visuals (or at least the inputs for them)
# decision tree
#tree=projectionToIndexedTree(data.frame(mtx) # for normalized minus foodiness dimension
tree=projectionToIndexedTree(data.frame(mtx[,c(2:12)]))
write(tree, "data-explorer/food-tree.json")

# scatter plot
projected.csv <- data.frame("image"=rownames(mtx),mtx)
write.csv(file="data-explorer/food-plot.csv",x=projected.csv,row.names = FALSE)

# food clusters based on hierarchical agglomerative clustering
dists = dist(mtx, method="euclidean")
clusters = hclust(dists, "ward.D2")
#labels = clusters$labels
#values <- data.frame(labels) %>%
#  mutate(value=labels, edited=1) %>%  
#  select(value, edited) 
# labeled withfor visualization
#tree = clusterToIndexedTree(clusters, values)
#write(tree,"data-explorer/labeled-food-clusters.json")
tree = clusterToIndexedTree(clusters)
write(tree,"data-explorer/food-clusters.json")


## get the nearest neigbors for food stats
distmtx = as.matrix(dists)
# nn = function(z){labels[order(z)[2:6]]}
neighbors = t(apply(distmtx,2,nn))

if(!all.equal(rownames(mtx),rownames(neighbors))) {
  stop("Error, inconsistent indices!")
}

foodspace.json = tibble(id=rownames(mtx), dims=mtx, neighbors=neighbors, updated=m$updated, edited=m$edited)
write(jsonlite::toJSON(foodspace.json), "to-export/foodStats.json")


## More output for mvp filtered visuals
mvp = meta %>% select(id,tag) %>% filter(tag=="_mvp")
m.mvp = mtx[mvp$id,]

dists = dist(m.mvp, method="euclidean")
clusters = hclust(dists, "ward.D2")
tree = clusterToIndexedTree(clusters)
write(tree,"data-explorer/food-clusters-mvp.json")
tree=projectionToIndexedTree(data.frame(m.mvp[,c(2:12)]))
write(tree, "data-explorer/food-tree-mvp.json")
projected.csv <- data.frame("image"=rownames(m.mvp),m.mvp)
write.csv(file="data-explorer/food-plot-mvp.csv",x=projected.csv,row.names = FALSE)

