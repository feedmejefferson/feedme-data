library(tidyverse)
library(jsonlite)
source("./load-meta.R")
source("./json-dendogram.R")

basket_name = "_mvp"

## load metadata for all foods
meta = load_moderator_foods("from-import/foods")

dictionary = load_tag_vectors()

tags = meta %>% 
  select(tag) %>% 
  group_by(tag) %>% 
  summarize(count=n())

tagspace <- tags %>% left_join(dictionary)
tagspace <- normalize0(tagspace)
tagmtx = as.matrix(tagspace %>% select(contains("X")))
rownames(tagmtx) <- tagspace$tag
p = as.matrix(read.table("projection-matrix-alt.txt"))
ptags = tagmtx %*% p
colnames(ptags)=paste("X",1:12, sep="") ## TODO: fix the javascript to be more forgiving
#ptags = normalize0(data.frame(ptags))
pdict = data.frame("tag"=rownames(ptags),ptags)



food_tags = meta %>% select(id, tag, edited, updated) %>% distinct_all()

## join these to our image ids and make sure none are missing
joined = food_tags %>%
  left_join(pdict) %>% ungroup()

grouped = joined %>%
  select(-tag) %>%
  #  group_by(id, tag.type) %>%
  group_by(id, edited, updated) %>%
  summarize_all(mean)

m = grouped %>% 
  ungroup()

## normalize after averaging? Ditch the first "foodiness" dimension? 
#mn = m %>% select(-c("X1"))  
#mn = normalize(mn)

# create a matrix using only the numeric vector columns
mtx = as.matrix(m %>% select(contains("X")))
# mtx = as.matrix(mn %>% select(contains("X"))) # using normalized matrix

# label the matrix rows with the food id
# TODO: create a better function for jumping between tidy and matrix forms
rownames(mtx)=m$id

## retrict the matrix to only the foods in our target basket
basket = meta %>% select(id,tag) %>% filter(tag==basket_name)
mtx = mtx[basket$id,]

## create the basket directory in case it doesn't yet exist
dir.create(file.path(".","baskets"))
dir.create(file.path("baskets",basket_name))

## Build all the snazzy visuals (or at least the inputs for them)
# decision tree
#tree=projectionToIndexedTree(data.frame(mtx) # for normalized minus foodiness dimension
tree=projectionToIndexedTree(data.frame(mtx[,c(2:12)]))
write(tree, paste("baskets",basket_name,"food-tree.json",sep="/"))

attributions = meta %>% 
  select(author, authorProfileUrl, id, license, licenseUrl, originTitle, originUrl, title) %>%
  distinct_all() %>%
  semi_join(basket)
write(jsonlite::toJSON(attributions), paste("baskets",basket_name,"attributions.json",sep="/"))

## finally, write out the vector files -- not using yet
#v = t(mtx)
#vectors = split(v, rep(1:ncol(v), each = nrow(v)))
#names(vectors) = rownames(mtx)
#write(jsonlite::toJSON(vectors), paste("baskets",basket_name,"vectors.json",sep="/"))


