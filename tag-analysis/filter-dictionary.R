## just a helper script to filter the full 400k word GloVe file

## load our list of tags and cannonicalize them for matching
source("./load-menu-and-tags.R")
taglist = food_tags %>% select(tag) %>% mutate(tag=gsub("[ -]","",tag)) %>% distinct()


## first you need to generate the tab delimited line number and term file
## just use sed and cat -n to strip everything but the term and then 
## prefix every line with the line number -- for instance:
#sed 's/ .*$//' glove.6B.50d.txt | cat -n >glove.terms.txt

dictionary.words <- read.delim2("~/sandbox/jfm/feedme-data/tag-analysis/glove/glove.terms.txt", header=FALSE, quote="", stringsAsFactors=FALSE)
colnames(dictionary.words) <- c("line", "word")

dictionary.words <- dictionary.words %>% 
  mutate(cannonical=gsub("[- ]","",word)) %>% 
  distinct(cannonical, .keep_all = TRUE) %>% 
  semi_join(taglist,by=c("cannonical"="tag"))

write_csv(dictionary.words,"glove/tag-list.csv")
## I manually removed some of the stop words at the beginning 
## of the list before creating our dictionary (of, and, etc)
##sed -n -f <(sed 's/,.*$/p/' tag-list.csv) ~/Downloads/glove.6B/glove.6B.300d.txt >new-dict
