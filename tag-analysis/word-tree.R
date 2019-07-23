library(tidyverse)
library(jsonlite)
source("./load-meta.R")

## load metadata for applicable foods
## -- focusing on fixed ones for now
#meta = load_meta_folder("fixed/photos")
meta = load_meta_folder("images/photos")
stop_tags = read_csv("stop-tags.txt", col_names = FALSE) %>%
  rename(tag=X1) 
meta = meta %>% anti_join(stop_tags)


## only use adams apple foods
## filter for adams apple hand selected demo foods
adams_apple = c("0000644.jpg","0000260.jpg","0000218.jpg","0000004.jpg","0000098.jpg","0000261.jpg","0000879.jpg","0000360.jpg","0000609.jpg","0000861.jpg","0000189.jpg","0000999.jpg","0000009.jpg","0000091.jpg","0000134.jpg","0000358.jpg","0000146.jpg","0000414.jpg","0000249.jpg","0000995.jpg","0000378.jpg","0000284.jpg","0000036.jpg","0000593.jpg","0000495.jpg","0000399.jpg","0000301.jpg","0000095.jpg","0000396.jpg","0000400.jpg","0000110.jpg","0000093.jpg","0000549.jpg","0000096.jpg","0000117.jpg","0000034.jpg","0000473.jpg","0000815.jpg","0000997.jpg","0000781.jpg")
meta = meta %>% filter(id %in% adams_apple)

tag_occurences = meta %>% 
  #  filter(tag.type=="isTags") %>%
  #  filter(tag.type=="containsTags") %>%
  #  filter(tag.type=="descriptiveTags") %>%
  group_by(tag) %>%
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

## use projection matrix created from svd on adams apple foods
p = as.matrix(read.table("projection-matrix.txt"))
projected = mtx %*% p
colnames(projected)=paste("X",1:10, sep="") ## TODO: fix the javascript to be more forgiving
rownames(projected) = rownames(mtx)

# scatter plot
projected.csv <- data.frame("image"=rownames(projected),projected)
write.csv(file="d3/word-scatter.csv",x=projected.csv,row.names = FALSE)



