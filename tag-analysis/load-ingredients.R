library(tidyverse)
library(tidytext)

ingredient_tokenizer <- function(comma_separated_ingredients) { 
  strsplit(tolower(comma_separated_ingredients),"([.,\n:;()*]|\\[|\\]|\\{|\\}| and )") 
}

comma_separated_tokenizer <- function(comma_separated_ingredients) { 
  strsplit(tolower(comma_separated_ingredients),",","") 
}

## I'm using two different food/ingredient data sets. 
## https://data.world/datafiniti/food-ingredient-lists
## https://ndb.nal.usda.gov/ndb/search/list?home=true
## so far the second one looks a lot cleaner
ingredients.csv <- read_csv("ingredients/ingredients.csv")

ingredients <- ingredients.csv %>%
  filter(features.key=="Ingredients") %>%
  select(features.value) %>%
  rename(unparsed=features.value) %>%
  unnest_tokens(ingredient, unparsed, token=ingredient_tokenizer) %>%
  mutate(ingredient=trimws(ingredient)) %>%
  filter(ingredient!="") %>%
  mutate(ingredient=gsub("[^a-z]", "", ingredient)) %>%
  count(ingredient)

FOOD_DES <- read_delim("ingredients/FOOD_DES.txt", "~", escape_double = FALSE, col_names = FALSE, trim_ws = TRUE)

ingredients2 <- FOOD_DES %>%
  select(X6) %>%
  rename(unparsed=X6) %>%
  unnest_tokens(ingredient, unparsed, token=comma_separated_tokenizer) %>%
  mutate(ingredient=trimws(ingredient)) %>%
  filter(ingredient!="") %>%
  mutate(ingredient=gsub("[^a-z]", "", ingredient)) %>%
  count(ingredient)

ingredients <- ingredients %>% union(ingredients2) %>% count(ingredient)
