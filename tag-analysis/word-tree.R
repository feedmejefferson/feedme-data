library(tidyverse)
library(jsonlite)
source("./load-meta.R")
source("./json-dendogram.R")

## load metadata for applicable foods
## -- focusing on fixed ones for now
#meta = load_meta_folder("fixed/photos")
meta = load_meta_folder("images/photos")
stop_tags = read_csv("stop-tags.txt", col_names = FALSE) %>%
  rename(tag=X1) 
meta = meta %>% anti_join(stop_tags)
remove = c("0000010","0000218","0000032","0000039","0000041","0000043","0000047","0000099","0000102","0000111","0000132","0000143","0000224","0001671","0003095","0003186","0003153","0003142","0003138","0003115","0003089","0003075","0003008","0001875","0001724","0001715","0001709","0001686","0001666","0001640","0001634","0001635","0001533","0001473","0001387","0001222","0001117","0001054","0001038","0001020","0001007","0001004","0001003","0000252","0000366","0000372","0000974","0000288","0000947","0000941","0000921","0000729","0000817","0000819","0000814","0000797","0003161","0003129","0003105")
meta = meta %>% filter(!(id %in% remove))

mvp = c("0000004","0000006","0000008","0000009","0000015","0000018","0000022","0000024","0000026","0000030","0000034","0000035","0000037","0000038","0000040","0000044","0000045","0000055","0000091","0000092","0000093","0000094","0000095","0000096","0000098","0000101","0000103","0000104","0000105","0000109","0000110","0000112","0000114","0000117","0000120","0000122","0000126","0000127","0000129","0000134","0000138","0000142","0000144","0000146","0000170","0000215","0000216","0000217","0000220","0000225","0000227","0000228","0000229","0000233","0000234","0000235","0000249","0000256","0000257","0000260","0000261","0000265","0000273","0000284","0000293","0000301","0000323","0000335","0000337","0000358","0000359","0000360","0000361","0000362","0000378","0000391","0000396","0000397","0000399","0000400","0000404","0000414","0000473","0000494","0000495","0000549","0000561","0000593","0000594","0000609","0000636","0000644","0000675","0000684","0000723","0000731","0000767","0000768","0000778","0000781","0000800","0000807","0000812","0000815","0000816","0000821","0000822","0000861","0000862","0000864","0000866","0000870","0000876","0000879","0000884","0000901","0000908","0000910","0000926","0000929","0000931","0000936","0000937","0000940","0000945","0000946","0000953","0000958","0000961","0000962","0000963","0000968","0000972","0000978","0000979","0000981","0000982","0000986","0000989","0000995","0000999","0001017","0001043","0001050","0001053","0001062","0001065","0001070","0001071","0001074","0001075","0001132","0001147","0001181","0001208","0001232","0001239","0001251","0001306","0001322","0001332","0001347","0001370","0001397","0001399","0001405","0001416","0001444","0001577","0001644","0001698","0001841","0001879","0003001","0003003","0003004","0003006","0003013","0003014","0003016","0003017","0003018","0003020","0003023","0003026","0003032","0003033","0003037","0003039","0003041","0003042","0003047","0003048","0003051","0003054","0003056","0003057","0003058","0003059","0003060","0003066","0003068","0003071","0003072","0003074","0003076","0003078","0003081","0003082","0003084","0003085","0003087","0003088","0003092","0003096","0003098","0003100","0003101","0003107","0003108","0003109","0003114","0003116","0003118","0003119","0003120","0003122","0003123","0003125","0003130","0003131","0003135","0003136","0003139","0003141","0003144","0003145","0003146","0003148","0003149","0003151","0003155","0003156","0003158","0003159","0003160","0003162","0003164","0003168","0003169","0003170","0003172","0003174","0003178","0003180","0003181","0003183","0003184","0003185","0003187","0003189","0003193","0003194","0003197","0003198","0003199","0003200","0003201","0003202","0003203")
mvp.tags = meta %>% filter(id %in% mvp) %>%
  group_by(id) %>% summarise_all(max) %>%
  mutate(tag.type="descriptiveTags", tag="_mvp", original.tag="_mvp")

meta = meta %>% union_all(mvp.tags)
#meta = meta %>% filter(id %in% mvp)

## only use adams apple foods
## filter for adams apple hand selected demo foods
#adams_apple = c("0000644.jpg","0000260.jpg","0000218.jpg","0000004.jpg","0000098.jpg","0000261.jpg","0000879.jpg","0000360.jpg","0000609.jpg","0000861.jpg","0000189.jpg","0000999.jpg","0000009.jpg","0000091.jpg","0000134.jpg","0000358.jpg","0000146.jpg","0000414.jpg","0000249.jpg","0000995.jpg","0000378.jpg","0000284.jpg","0000036.jpg","0000593.jpg","0000495.jpg","0000399.jpg","0000301.jpg","0000095.jpg","0000396.jpg","0000400.jpg","0000110.jpg","0000093.jpg","0000549.jpg","0000096.jpg","0000117.jpg","0000034.jpg","0000473.jpg","0000815.jpg","0000997.jpg","0000781.jpg")
#meta = meta %>% filter(id %in% adams_apple)

tag_occurences = meta %>% 
  #  filter(tag.type=="isTags") %>%
  #  filter(tag.type=="containsTags") %>%
  #  filter(tag.type=="descriptiveTags") %>%
  group_by(tag) %>%
  summarize(n=n(), pretty=first(original.tag))

tag_occurences2 = meta %>% 
  #  filter(tag.type=="isTags") %>%
  #  filter(tag.type=="containsTags") %>%
  #  filter(tag.type=="descriptiveTags") %>%
  group_by(tag, tag.type) %>%
  summarize(n=n()) %>%
  spread(key=tag.type, value=n, fill=0)

## cluster the tags that show up in our dictionary
##by their word embeddings (pseudo meaning)
dictionary <- load_tag_vectors()
#dictionary <- normalize(dictionary)
#mvp.row <- dictionary %>% head(1) %>% mutate_all(function(x) 0) %>% mutate(tag="_mvp")
#no.tag.row <- dictionary %>% head(1) %>% mutate_all(function(x) 0) %>% mutate(tag="_no_tags")
#dictionary <- dictionary %>% union_all(mvp.row) %>% union_all(no.tag.row)
tagspace = inner_join(tag_occurences,dictionary)


labels <- tagspace$tag
#counts <- tagspace$n
pretty <- tagspace$pretty
values <- tagspace %>% 
  mutate(value=tag, size=n) %>%
  select(value, size) 
tagspace <- tagspace %>% select(contains("X"))
mtx = as.matrix(tagspace)
#values <- data.frame(labels,counts)

rownames(mtx) <- labels
d <- dist(mtx)
clusters <- hclust(d)

JSON <- clusterToIndexedTree(clusters, values)
write(JSON, "d3/word-tree.json")

## use projection matrix created from svd on adams apple foods
p = as.matrix(read.table("projection-matrix.txt"))
projected = mtx %*% p
colnames(projected)=paste("X",1:12, sep="") ## TODO: fix the javascript to be more forgiving
rownames(projected) = rownames(mtx)

# scatter plot
projected.csv <- data.frame("image"=rownames(projected),projected)
write.csv(file="d3/word-scatter.csv",x=projected.csv,row.names = FALSE)


distmtx = as.matrix(d)
nn = function(z){labels[order(z)[2:6]]}
neighbors = t(apply(distmtx,2,nn))

if(!all.equal(rownames(projected),rownames(neighbors))) {
  stop("Error, inconsistent indices!")
}

tags.json = tibble(id=rownames(projected), pretty=pretty, dims=projected, neighbors=neighbors)
j = tags.json %>% left_join(tag_occurences2, by=c("id"="tag"))
#write(jsonlite::toJSON(tags.json), "d3/tags.json")
write(jsonlite::toJSON(j), "moderator/tagStats.json")

##
## I guess this is the tidyverse way to create nested lists
##
# t = data.frame(neighbors)
# t$tag = rownames(neighbors)
# t %>% gather("key", "neighbor", X1, X2, X3, X4, X5) %>% 
#   arrange(tag, key) %>% select(-key) %>% chop(neighbor) %>%
#   left_join(tag_occurences2) %>% head %>% toJSON()

## create an inverted index listing foods for tags
tagFoods = meta %>% select(id, tag) %>% 
  distinct_all() %>%
  mutate(foods=id,id=tag) %>%
  select(id, foods) %>%
  arrange(id, foods) %>% 
  chop(foods) 
write(jsonlite::toJSON(tagFoods), "moderator/tagFoods.json")


