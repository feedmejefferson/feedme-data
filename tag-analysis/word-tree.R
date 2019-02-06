library(tidyverse)
library(tidytext)
library(jsonlite)

## create a custom tokenizer that extracts tags from a comma 
## separated list but leaves ngram (multiword) tags intact
tag_tokenizer <- function(comma_separated_tags) { 
  strsplit(tolower(comma_separated_tags),"[,\n]") 
}

## get the list of active foods currently live on the site  
menu <- read_json('./images/menu.json', simplifyVector = TRUE)
## ignore flickr images for now until we can clean up their tags
menu <- menu[grep('000[01]....jpg',menu)]

## read and tokenize the tags for each of the food images
food_tags <- menu %>% 
  map_df(~ data_frame(
    text = read_file(paste0("./images/tags/", .x ,".txt")),
    food = .x
  )) %>% 
  unnest_tokens(tag, text, token=tag_tokenizer)


## how many times does each tag show up across all foods
tag_occurences <- food_tags %>% 
  count(tag) 


## cluster the tags that show up in our dictionary
##by their word embeddings (pseudo meaning)
dictionary <- read_delim("glove/filtered-dictionary.txt"," ", col_names = FALSE) 
colnames(dictionary)[1] <- "tag"
tagspace = inner_join(tag_occurences,dictionary)


labels <- tagspace$tag
counts <- tagspace$n
tagspace <- tagspace[,-c(1,2)]
values <- data.frame(labels,counts)

rownames(tagspace) <- labels
d <- dist(tagspace)
clusters <- hclust(d)

source("./json-dendogram.R")
JSON <- toJsonWeightedTree(clusters,values)
write(JSON, "d3/word-tree.json")

