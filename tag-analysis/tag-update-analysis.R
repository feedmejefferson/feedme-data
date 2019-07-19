## We (mostly Karen) have been manually editing the tags
## and other metadata associated with our images. This
## script is intended to get a feel for what that work has
## both encompassed and accomplished. 
##
## This is based mostly on work from the ladle project 
## which added a few tools for importing and exporting 
## our data to and from firebase's dynamic "firestore". 
## Everything started with a convert script that converted
## the old metadata format over to a consolidated json file
## format -- both tags and attributions. Then we manually
## updated the tags and titles using a web based editor. 
## The converted meta data files were pushed to a read only
## source hosted in a folder next to the actual images in 
## the images repository (or firebase's cloud storage) and
## then if edited, the edited copy was saved in the dynamic
## firestore backend. Finally, the updated version was 
## exported using ladle to a "fixed" directory. 
##
## This script compares the files in that "fixed" directory
## to the original "converted" files.

library(tidyverse)
library(jsonlite)

load_meta_folder = function(folder) {
  fs::dir_ls(folder, regexp = "\\.jpg$") %>%
    map_dfr(ndjson::stream_in) %>%
    gather("tag.type", 
           "tag", 
           -c(id, title, 
              originTitle, originUrl, 
              author, authorProfileUrl, 
              license, licenseUrl)) %>%
    mutate(tag.type=gsub("\\..*$", "", tag.type), 
           tag=tolower(tag)) %>%
    filter(!is.na(tag)) 
}


fixed = load_meta_folder("fixed/photos")
original = load_meta_folder("converted/photos")



## let's only look at the ones that have been modified
## ie exclude originals that haven't been "fixed"
fids = unique(fixed$id)
orig = original %>% filter(id %in% fids)

## let's just compare tags (skip titles and tag type)
f = fixed %>% select(id, tag) %>% arrange(id, tag)
o = orig %>% select(id, tag) %>% arrange(id, tag)

kept = intersect(o, f) %>% mutate(status="kept")
added = setdiff(f, o)  %>% mutate(status="added")
removed = setdiff(o, f)  %>% mutate(status="removed")

## for the ones that were kept it might still ne nice to know
## if they were recategorized

u = kept %>% union(added) %>% union(removed)
tag.stats = u %>% group_by(tag, status) %>% 
  summarise(count=n()) %>% 
  spread(key=status, value=count, fill=0) %>%
  mutate(count=added+kept+removed) %>% 
  mutate(pivot=(removed+kept+1)/(added+kept+1)) %>% 
  arrange(pivot)

food.stats = u %>% group_by(id, status) %>% 
  summarise(count=n()) %>% 
  spread(key=status, value=count, fill=0) %>%
  mutate(count=added+kept+removed) %>% 
  mutate(pivot=(removed+kept+1)/(added+kept+1)) %>% 
  arrange(pivot)

## we can potentially use high pivot scores to auto filter
## tags that don't have value



