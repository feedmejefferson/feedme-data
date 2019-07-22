library(tidyverse)
library(jsonlite)
source("./load-meta.R")

## load metadata for applicable foods
## -- focusing on fixed ones for now
#meta = load_meta_folder("fixed/photos")
meta = load_meta_folder("images/photos")

stop_tags = read_csv("stop-tags.txt", col_names = FALSE) %>%
  rename(tag=X1) 

tag_occurences = meta %>% 
  #  filter(tag.type=="isTags") %>%
  #  filter(tag.type=="containsTags") %>%
  #  filter(tag.type=="descriptiveTags") %>%
  group_by(tag) %>%
  anti_join(stop_tags) %>%
  summarize(n=n())


## cluster the tags that show up in our dictionary
##by their word embeddings (pseudo meaning)
dictionary <- load_tag_vectors()
dictionary <- normalize(dictionary)
tagspace = inner_join(tag_occurences,dictionary)


labels <- tagspace$tag
counts <- tagspace$n
tagspace <- tagspace %>% select(contains("X"))
mtx = as.matrix(tagspace)
values <- data.frame(labels,counts)

rownames(mtx) <- labels
d <- dist(mtx)
clusters <- hclust(d)

source("./json-dendogram.R")
JSON <- toJsonWeightedTree(clusters,values)
write(JSON, "d3/word-tree.json")

## try it with pca
## run pca on the food_meaningspace
dvu <- svd(mtx)
dvu$d[1:10]

rownames(dvu$u) <- rownames(mtx)
#u <- dvu$u[,1:20]
u <- mtx[,1:20]
u.csv <- data.frame("image"=rownames(u),u)
#v <- left_join(views, v)
write.csv(file="d3/word-scatter.csv",x=u.csv,row.names = FALSE)


