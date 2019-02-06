library(tidyverse)
library(tidytext)
library(jsonlite)

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
    image_name = .x
  )) %>% 
  unnest_tokens(tag, text, token=tag_tokenizer) %>%
  mutate(value=1)

points = spread(food_tags, tag, value, fill=0)

## force our tibble back to a standard dataframe 
## tibbles don't like rownames which hclust labels rely on
## TODO: there's probably a better way to fix this
points <- data.frame(points)
rownames(points) <-points$image_name
points <- within(points, rm("image_name"))

#points <- t(points)
# remove tags that only show up once
cutoff <- 1
points <- points[,colSums(points[,])>cutoff]

# use tf/idf like weighting -- give common tags less signficance
idf <- log(nrow(points)/colSums(points))
points <- points * idf

# remove "stop words" -- in this case the food tag
# maybe not as important if we're inverse weighting common tags
#points = points[,colnames(points)!="food"]

# normalize the points to all be unit vectors
points = points/(rowSums(points^2)^.5)

# uncomment the following row to look at a smaller sample
#samp = sample(1:nrow(points),64)
#points = points[samp,]
## binary works well enough without normalization and combined with either ward clustering method
## euclidian works well as well, but needs to be normalized, in general, ward
## clustering seems to offer the most balanced trees
dists = dist(points)
clusters = hclust(dists, "ward.D2")
#plot(clusters)
#m=as.matrix(dists)


source("./json-dendogram.R")
## write out the food clusters file for the d3.js food explorer
JSON <- toLabeledJsonNodeTree(clusters)
write(JSON, "d3/food-clusters.json")
## write out the simplified food tree for crystal bowl
JSON <- toJsonNodeTree(clusters)
write(JSON, "d3/tree.json")
#points.matrix <- as.matrix(points)
#D3Dendo(JSON, file_out="d3/dendo.html")



#dvu <- svd(points.matrix)
#dvu$d[1:10]
#rownames(dvu$v) <- colnames(points.matrix)
#v <- dvu$v[,1:10]
#v <- data.frame("image"=rownames(v),"S"=c(1),"C"=c(1),"U"=c(1),v)
#write.csv(file="d3/pca-scatter.csv",x=v,row.names = FALSE)

