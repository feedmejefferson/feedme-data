source("./load-menu-and-tags.R")
source("./load-stoplist.R")

## cannonicalize the tags -- map all hyphenated and space
## spearated tags to the same cannonical version -- thus
## "close up", "closeup", "close-up" and even "close- up"
## will all be treated as the same tag "closeup"
## if any foods are tagged with multiple versions we'll
## remove the duplicates created here so as not to over
## weight them
food_tags <- mutate(food_tags, tag=gsub("[ -]","",tag)) %>%
  anti_join(stoplist) %>%
  distinct()
  

## how many times does each tag show up across all foods
#tag_occurences <- food_tags %>% 
#  count(tag) 


## cluster the tags that show up in our dictionary
##by their word embeddings (pseudo meaning)
dictionary <- read_delim("glove/filtered-dictionary.txt"," ", col_names = FALSE) 

## the first column in the dictionary is the term being defined
## the rest of the columns form a numeric vector with the word
## embedding. Some compound words show up hyphenated and not
## hyphenated. The terms are sorted in decreasing frequency,
## so in our case we will remove hyphens from all terms to form
## a cannonical term and remove all duplicates after the first
## to use the map either version to the most frequently used one
dictionary <- 
  rename(dictionary, tag=X1) %>%
  mutate(tag=gsub("[ -]","",tag)) %>%
  distinct(tag, .keep_all = TRUE) %>%
  semi_join(food_tags) %>%
  arrange(tag)

## remove tags that aren't in our dictionary from the food tagspace
food_tags <- food_tags %>% semi_join(dictionary)
#food_tags$value <- 0

source("./load-ingredients.R")
ingredients <- ingredients %>% semi_join(dictionary, by=c("ingredient"="tag"))
ingredients$n=1  ## try an arbitrary upweighting for ingredients

food_tagspace <- food_tags %>% 
  rename(food_=food) %>%
  mutate(value=1) %>%
  left_join(ingredients, by=c("tag"="ingredient")) %>%
  mutate(n=replace_na(n,0)) %>%
  mutate(value=value+n) %>%
  select(food_, tag, value) %>%
  spread(tag, value, fill=0)

# convert our tagspace of foods to a matrix
m = as.matrix(food_tagspace[,-1])
dimnames(m)[1]<-food_tagspace[,1]
food_tagspace <- m
rm(m)

# convert dictionary to a matrix representing our meaningspace of tags
tag_meaningspace <- as.matrix(dictionary[,-1])
dimnames(tag_meaningspace)[1] <- dictionary[,1]

## if we want to do any kind of tag weighting (like 
## inverse document frequency), this it should happen here
idf <- log(nrow(food_tagspace)/colSums(food_tagspace!=0))
food_tagspace <- food_tagspace * idf

## check that our matrix rows and columns match up for projection
if(!all(dimnames(tag_meaningspace)[[1]]==dimnames(food_tagspace)[[2]])) { 
  stop("Not all column/rows match up for matrix multiplication, stopping now.")
}

food_meaningspace <- food_tagspace %*% tag_meaningspace
## normalize the output to unit vectors
food_meaningspace = food_meaningspace/(rowSums(food_meaningspace^2)^.5)


#rownames(tagspace) <- labels
d <- dist(food_meaningspace)
clusters <- hclust(d)

source("./json-dendogram.R")
JSON <- toLabeledJsonNodeTree(clusters)
write(JSON, "d3/food-clusters.json")


## run pca on the food_meaningspace
dvu <- svd(food_meaningspace)
dvu$d[1:10]


rownames(dvu$u) <- rownames(food_meaningspace)
u <- dvu$u[,1:15]
u.csv <- data.frame("image"=rownames(u),u)
#v <- left_join(views, v)
write.csv(file="d3/pca-scatter.csv",x=u.csv,row.names = FALSE)

dimension = 1
subset = data.frame(u)

vsplit <- function(df, n=2) {
  l = nrow(df)
  r = l/n
  return(lapply(1:n, function(i) {
    s = max(1, round(r*(i-1))+1)
    e = min(l, round(r*i))
    return(df[s:e,])
  }))
}


buildNode <- function(subset, dimension) {
  l = nrow(subset)
  name=c(rownames(subset)[ceiling(l/2)])
  if(l<2) {
    return(list(names=c(name,name)))
  } else {
    sorted = subset[order(subset[,dimension]),]
    children=lapply(vsplit(sorted),function(x) {buildNode(x,dimension+1)})
    return(list(names=c(name,name),children=children))
  }
}

## starting with the second dimension as the first one
## isn't really capturing the type of information we want
node=buildNode(subset,2)

JSON=toJSON(node)
write(JSON, "d3/food-clusters.json")

