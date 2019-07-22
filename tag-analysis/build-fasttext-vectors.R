library(tidyverse)
library(jsonlite)
source("load-meta.R")

## load all of the metadata -- for now we're only loading fixed
#fixed = load_meta_folder("fixed/photos")
fixed = load_meta_folder("images/photos")

tags = fixed %>% select(tag) %>% 
  group_by(tag) %>%
  summarize()

titles = fixed %>% 
  select(title) %>% distinct_all()

write(tags$tag, "fasttext/tags.txt")
write(titles$title, "fasttext/titles.txt")


## Now manually go into the fasttext directory and run the 
## fasttext print-word/senctence-vector commands