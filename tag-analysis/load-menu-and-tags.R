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
  unnest_tokens(tag, text, token=tag_tokenizer) %>%
  unnest_tokens(tag, tag, token="skip_ngrams", collapse=FALSE)

