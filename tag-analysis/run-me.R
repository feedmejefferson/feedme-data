library(tidyverse)
library(tidytext)
library(scales)
library(jsonlite)

## create a custom tokenizer that extracts tags from a comma 
## separated list but leaves ngram (multiword) tags intact
tag_tokenizer <- function(comma_separated_tags) { 
  strsplit(tolower(comma_separated_tags),"[,\n]") 
}

## get the list of active foods currently live on the site  
menu <- read_json('./images/menu.json', simplifyVector = TRUE)

## read and tokenize the tags for each of the food images
food_tags <- menu %>% 
  map_df(~ data_frame(
    text = read_file(paste0("./images/tags/", .x ,".txt")),
    food = .x
  )) %>% 
  unnest_tokens(tag, text, token=tag_tokenizer)

## at this point we have a skinny formatted dataset
head(food_tags)

## how many times does each tag show up across all foods
tag_occurences <- food_tags %>% 
  count(tag) 

## how many tags does each food have
food_tag_counts <- food_tags %>% 
  count(food) 

## plot the top 20 tags by the number of foods they occur in
tag_occurences %>%
  filter(n>50) %>% 
  mutate(tag=reorder(tag,n)) %>% 
  top_n(20) %>%
  ggplot(aes(tag, n)) + 
  geom_col() + 
  coord_flip()

## plot histogram of tag occurrences
tag_occurences %>%
  ggplot +
  aes(x=n) +
  xlab("Tag Occurrence") + 
  ylab("Number of Tags") +
  geom_histogram() 

## plot it on a log scale for the y axis
tag_occurences %>%
  ggplot +
  aes(x=n) +
  xlab("Tag Occurrence") + 
  ylab("Number of Tags") +
  geom_histogram() +
  scale_y_continuous(trans=log10_trans()) 

## plot it on a log scale for both axes using log scaled bins
tag_occurences %>%
  ggplot +
  aes(x=n) +
  xlab("Tag Occurrence") + 
  ylab("Number of Tags") +
  geom_histogram(breaks=2^(0:10)-.001) +
  scale_y_continuous(trans=log10_trans()) +
  scale_x_continuous(trans=log2_trans())

## histogram for tag count by food
food_tag_counts %>%
  ggplot +
  aes(x=n) +
  xlab("Number of Foods with") +
  ylab("Number of Tags") + 
  geom_histogram(binwidth=2) 
  


dictionary = read_delim("glove/filtered-dictionary.txt"," ", col_names = FALSE)
labels <- dictionary$X1
dictionary <- dictionary[,-1]
rownames(dictionary) <- labels
d <- dist(dictionary)
clusters <- hclust(d)

source("./json-dendogram.R")
JSON <- toJsonNodeTree(clusters)
write(JSON, "d3/word-tree.json")

