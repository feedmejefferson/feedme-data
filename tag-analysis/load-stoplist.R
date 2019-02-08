library(tidyverse)
library(tidytext)

stoplist <- read_csv("stop-tags.txt", col_names = FALSE)

## load and standardize/cannonicalize the tags
stoplist <- stoplist %>%
  rename(tag=X1) %>%
  mutate(tag=gsub("[ -]", "", tag)) %>%
  distinct()

