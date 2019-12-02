library(tidyverse)
library(jsonlite)
source("./load-meta.R")
source("./json-dendogram.R")


## load metadata for applicable foods
## -- focusing on fixed ones for now
#meta = load_moderator_foods("from-moderator/foods")
dictionary = load_tag_vectors()

## renormalize each of our food vectors to unit length
m = normalize0(dictionary)

# create a matrix using only the numeric vector columns
mtx = as.matrix(m %>% select(contains("X")))
rownames(mtx)=m$tag

###
### Use svd to find the projection matrix (it's basically
### the first N columns of the V decomposition). Here we're
### choosing to only maintain 12 dimensions.
###
s <- svd(mtx)
rank = 1:12
# mtx = s$u %*% diag(s$d)  %*% t(s$v)
# mtx =~ s$u[,rank] %*% diag(s$d[rank])  %*% t(s$v)[rank,]
# mtx %*% s$v = s$u %*% diag(s$d) 
# mtx %*% (projection matrix) = (projected matrix)
# thus s$v[,rank] = projection matrix!!
p = s$v[,rank]


## use the projection matrix to project the food vectors onto
## a lower dimensional space, then build all three visuals
projected = mtx %*% p

# scatter plot
projected.csv <- data.frame("image"=rownames(projected),projected)
write.csv(file="data-explorer/build-projection1.csv",x=projected.csv,row.names = FALSE)

## we clearly have two clusters -- regular and compound words
## let's filter out all of the compound words and try again
altmtx = mtx[projected[,2]>0,]
s <- svd(altmtx)
p = s$v[,rank]
projected = altmtx %*% p
projected.csv <- data.frame("image"=rownames(projected),projected)
write.csv(file="data-explorer/build-projection2.csv",x=projected.csv,row.names = FALSE)

## perfect, now we can see that the first dimension is basically
## telling us how relevant each tag is to food. If we pick a cutoff
## like negative .5 then we can eliminate all of less foody tags
foodish = altmtx[projected[,1] < -.50,]
s <- svd(foodish)

p = s$v[,rank]
write.table(p, file="projection-matrix-alt.txt", row.names=FALSE, col.names=FALSE)
projected = altmtx %*% p
projected.csv <- data.frame("image"=rownames(projected),projected)
write.csv(file="data-explorer/build-projection3.csv",x=projected.csv,row.names = FALSE)
