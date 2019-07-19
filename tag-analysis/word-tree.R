library(tidyverse)
library(jsonlite)
source("./load-meta.R")

## load metadata for applicable foods
## -- focusing on fixed ones for now
meta = load_meta_folder("fixed/photos")
tag_occurences = meta %>% 
  #  filter(tag.type=="isTags") %>%
    filter(tag.type=="containsTags") %>%
  #  filter(tag.type=="descriptiveTags") %>%
  group_by(tag) %>%
  summarize(n=n())

## cluster the tags that show up in our dictionary
##by their word embeddings (pseudo meaning)
dictionary <- load_tag_vectors()
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

