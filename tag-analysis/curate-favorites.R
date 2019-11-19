library(tidyverse)
library(jsonlite)
source("./load-meta.R")
source("./json-dendogram.R")


## load metadata for applicable foods
## -- focusing on fixed ones for now
meta = load_meta_folder("images/photos")

## identify which metadata entries have or haven't yet been edited
edited = meta %>% 
  group_by(id, title, originTitle, tag.type) %>% 
  summarize(count=n()) %>% 
  spread(key=tag.type, value=count) %>% 
  mutate(edited = !(title==originTitle & is.na(descriptiveTags) & is.na(isTags))) %>% 
  ungroup() %>%
  select(id, edited)

stop_tags = read_csv("stop-tags.txt", col_names = FALSE) %>%
  rename(tag=X1) 
meta = meta %>% anti_join(stop_tags)

## remove flagged foods (see images to remove tag from google sheet)
remove = c("0000010","0000218","0000032","0000039","0000041","0000043","0000047","0000099","0000102","0000111","0000132","0000143","0000224","0001671","0003095","0003186","0003153","0003142","0003138","0003115","0003089","0003075","0003008","0001875","0001724","0001715","0001709","0001686","0001666","0001640","0001634","0001635","0001533","0001473","0001387","0001222","0001117","0001054","0001038","0001020","0001007","0001004","0001003","0000252","0000366","0000372","0000974","0000288","0000947","0000941","0000921","0000729","0000817","0000819","0000814","0000797","0003161","0003129","0003105")
## adam/karen voted against these for the mvp
#not.mvp = c("0000002","0000010","0000032","0000036","0000039","0000041","0000043","0000047","0000049","0000064","0000070","0000075","0000088","0000102","0000111","0000113","0000116","0000130","0000141","0000143","0000147","0000152","0000153","0000159","0000165","0000166","0000186","0000189","0000191","0000202","0000208","0000210")
#not.mvp = c("0000002","0000010","0000032","0000036","0000039","0000041","0000043","0000047","0000049","0000102","0000111","0000113","0000116","0000141","0000143","0000166","0000189","0000191","0000208","0000218","0000252","0000288","0000366","0000372","0000729","0000797","0000814","0000817","0000819","0000921","0000941","0000947","0000974","0001003","0001004","0001007","0001020","0001038","0001054","0001117","0001222","0001387","0001473","0001533","0001634","0001635","0001640","0001666","0001671","0001686","0001709","0001715","0001724","0001875","0003008","0003043","0003044","0003045","0003046","0003049","0003050","0003052","0003053","0003055","0003061","0003062","0003063","0003064","0003067","0003069","0003070","0003073","0003075","0003077","0003079","0003080","0003086","0003089","0003090","0003091","0003093","0003094","0003095","0003097","0003099","0003103","0003104","0003106","0003110","0003111","0003112","0003113","0003115","0003121","0003124","0003126","0003127","0003128","0003132","0003133","0003134","0003137","0003138","0003139","0003140","0003142","0003143","0003145","0003147","0003150","0003153","0003154","0003157","0003161","0003163","0003165","0003167","0003173","0003175","0003176","0003177","0003179","0003186","0003188","0003191","0003195","0003196")
mvp = c("0000004","0000006","0000008","0000009","0000015","0000018","0000022","0000024","0000026","0000030","0000034","0000035","0000037","0000038","0000040","0000044","0000045","0000055","0000091","0000092","0000093","0000094","0000095","0000096","0000098","0000101","0000103","0000104","0000105","0000109","0000110","0000112","0000114","0000117","0000120","0000122","0000126","0000127","0000129","0000134","0000138","0000142","0000144","0000146","0000170","0000215","0000216","0000217","0000220","0000225","0000227","0000228","0000229","0000233","0000234","0000235","0000249","0000256","0000257","0000260","0000261","0000265","0000273","0000284","0000293","0000301","0000323","0000335","0000337","0000358","0000359","0000360","0000361","0000362","0000378","0000391","0000396","0000397","0000399","0000400","0000404","0000414","0000473","0000494","0000495","0000549","0000561","0000593","0000594","0000609","0000636","0000644","0000675","0000684","0000723","0000731","0000767","0000768","0000778","0000781","0000800","0000807","0000812","0000815","0000816","0000821","0000822","0000861","0000862","0000864","0000866","0000870","0000876","0000879","0000884","0000901","0000908","0000910","0000926","0000929","0000931","0000936","0000937","0000940","0000945","0000946","0000953","0000958","0000961","0000962","0000963","0000968","0000972","0000978","0000979","0000981","0000982","0000986","0000989","0000995","0000999","0001017","0001043","0001050","0001053","0001062","0001065","0001070","0001071","0001074","0001075","0001132","0001147","0001181","0001208","0001232","0001239","0001251","0001306","0001322","0001332","0001347","0001370","0001397","0001399","0001405","0001416","0001444","0001577","0001644","0001698","0001841","0001879","0003001","0003003","0003004","0003006","0003013","0003014","0003016","0003017","0003018","0003020","0003023","0003026","0003032","0003033","0003037","0003039","0003041","0003042","0003047","0003048","0003051","0003054","0003056","0003057","0003058","0003059","0003060","0003066","0003068","0003071","0003072","0003074","0003076","0003078","0003081","0003082","0003084","0003085","0003087","0003088","0003092","0003096","0003098","0003100","0003101","0003107","0003108","0003109","0003114","0003116","0003118","0003119","0003120","0003122","0003123","0003125","0003130","0003131","0003135","0003136","0003139","0003141","0003144","0003145","0003146","0003148","0003149","0003151","0003155","0003156","0003158","0003159","0003160","0003162","0003164","0003168","0003169","0003170","0003172","0003174","0003178","0003180","0003181","0003183","0003184","0003185","0003187","0003189","0003193","0003194","0003197","0003198","0003199","0003200","0003201","0003202","0003203")
## as of october 1, removing the above and all of the images
## that haven't yet been edited gets us down to 547 -- if we want
## to target exactly 512 for the mvp, for better or worse I'm 
## just going to remove half of the most similarly tagged images
## based on hierarchical clustering (no effort went in to deciding
## which of the two most similar images should be selected)
#most.redundant = c("0000293","0000404","0000670","0000807","0000972","0001359","0003001","0003097","0003110","0003160","0000981","0003033","0000095","0000112","0003126","0003132","0000778","0000362","0003067","0003105","0000989","0000884","0001255","0000946","0001904","0000768","0003035","0003055","0000561","0000391","0000864","0000926","0000731","0001069")
#meta = meta %>% filter(id %in% mvp)
meta = meta %>% filter(!(id %in% remove))

####
#### create a title space for calculating similarity
####
#title_vectors = load_title_vectors()
#ids = meta %>% group_by(id, title) %>% summarise() %>%
#  select(id,title) 
## join these to our image ids and make sure none are missing
#joined = meta %>% group_by(id, title) %>% summarise() %>%
#  select(id,title) %>%
#  inner_join(title_vectors) 


####
#### use multiple tag spaces depending on tag type to
#### determine similarity -- give greatest significance
#### to "isTags", less weighting to contains and descriptive
####
tag_vectors = load_tag_vectors()
#tag_vectors = normalize(tag_vectors)

#food_tags = meta %>% select(id, tag.type, tag) %>% distinct_all()
food_tags = meta %>% select(id, tag) %>% distinct_all()

## join these to our image ids and make sure none are missing
joined = food_tags %>%
  inner_join(tag_vectors) %>% ungroup()

grouped = joined %>%
  select(-tag) %>%
  #  group_by(id, tag.type) %>%
  group_by(id) %>%
  summarize_all(mean)

m = grouped %>% 
  #  filter(tag.type=="containsTags") %>% 
  #  filter(tag.type=="isTags") %>% 
  #  filter(tag.type=="descriptiveTags") %>% 
  #  select(-tag.type) %>%
  ungroup()

## normalize after averaging?
#m = normalize(m)

# create a matrix using only the numeric vector columns
mtx = as.matrix(m %>% select(contains("X")))
# label the matrix rows with the food id
rownames(mtx)=m$id



## run some agglomerative hierarchical clustering
#dists = dist(mtx, method="euclidean")
#clusters = hclust(dists, "ward.D2")
## write out the food clusters file for the d3.js food explorer
#JSON <- toLabeledJsonNodeTree(clusters)
#write(JSON, "d3/food-tree.json")


## use random projection approach
#library(RandPro)
#set.seed(3456)
#p=form_matrix(300,20,FALSE)
## use projection matrix created from svd on adams apple foods
p = as.matrix(read.table("projection-matrix.txt"))
projected = mtx %*% p
colnames(projected)=paste("X",1:12, sep="") ## TODO: fix the javascript to be more forgiving
rownames(projected) = rownames(mtx)


## Build all the snazzy visuals (or at least the inputs for them)

# scatter plot
projected.csv <- data.frame("image"=rownames(projected),projected)
projected.csv <- projected.csv %>% left_join(edited, by = c("image"="id"))
write.csv(file="d3/food-plot.csv",x=projected.csv,row.names = FALSE)

# decision tree
JSON=projectionToIndexedTree(data.frame(projected[,c(2:12)]))
write(JSON, "d3/food-tree.json")

# food clusters
dists = dist(projected, method="euclidean")
clusters = hclust(dists, "ward.D2")
labels = clusters$labels
values <- data.frame(labels) %>%
  left_join(edited, by=c("labels"="id")) %>%
  mutate(value=labels) %>%
  select(value, edited) 
tree = clusterToIndexedTree(clusters, values)
write(tree,"d3/labeled-food-clusters.json")
tree = clusterToIndexedTree(clusters)
write(tree,"d3/food-clusters.json")


# write out the basket files
v = t(projected)
vectors = split(v, rep(1:ncol(v), each = nrow(v)))
names(vectors) = gsub(".jpg","",rownames(projected))
write(jsonlite::toJSON(vectors), "d3/vectors.all.json")

attributions = meta %>% 
  select(author, authorProfileUrl, id, license, licenseUrl, originTitle, originUrl, title) %>%
  distinct_all()

write(jsonlite::toJSON(attributions), "d3/attributions.all.json")

distmtx = as.matrix(dists)
nn = function(z){labels[order(z)[2:6]]}
neighbors = t(apply(distmtx,2,nn))

if(!all.equal(rownames(projected),rownames(neighbors))) {
  stop("Error, inconsistent indices!")
}

## I really don't like this, but until I can refactor using
## chop et al, it'll have to do...
updatedVector = ifelse(edited$edited[match(rownames(projected),edited$id)], "2019-09-01T00:00:00.000Z", "2019-03-01T00:00:00.000Z")
foodspace.json = tibble(id=rownames(projected), dims=projected, neighbors=neighbors, updated=updatedVector, edited=updatedVector)
write(jsonlite::toJSON(foodspace.json), "moderator/foodStats.json")

mvp.tags = meta %>% filter(id %in% mvp) %>%
  group_by(id) %>% summarise_all(max) %>%
  mutate(tag.type="descriptiveTags", tag="_mvp", original.tag="_mvp")
#  mutate(tag.type="allTags") %>% distinct() %>% union(meta) %>% 

#all.tags = meta %>% 
#  mutate(tag.type="allTags") %>% distinct() %>% union(meta) %>% 
foods.json = meta %>% union_all(mvp.tags) %>%
  select(c(-original.tag)) %>% 
  left_join(edited) %>% 
  mutate(
    updated=ifelse(edited, "2019-09-01T00:00:00.000Z", "2019-03-01T00:00:00.000Z")
  ) %>%
  mutate(edited=updated) %>% 
  chop(tag) %>% spread(tag.type, tag)
write(jsonlite::toJSON(foods.json), "moderator/foods.json")



