library(tidyverse)
library(jsonlite)
source("./load-meta.R")
source("./json-dendogram.R")




## load metadata for applicable foods
## -- focusing on fixed ones for now
#meta = load_moderator_foods("from-moderator/foods")
dictionary = load_tag_vectors()
cuisines = load_tag_vectors("./fasttext/cuisine-vectors.txt")
ergonomics = load_tag_vectors("./fasttext/ergonomic-vectors.txt")

## renormalize each of our food vectors to unit length
m = normalize0(dictionary)
c = normalize0(cuisines)
e = normalize0(ergonomics)
#c = cuisines
#m = dictionary
#e = ergonomics

mtx = as.matrix(m %>% select(contains("X")))
c.mtx = as.matrix(c %>% select(contains("X")))
e.mtx = as.matrix(e %>% select(contains("X")))
# label the matrix rows with the food id
rownames(mtx)=m$tag
rownames(c.mtx)=c$tag
rownames(e.mtx)=e$tag


## we're going to use the same steps that we used in 
## build-projection-matrix.R to filter out compound words 
## and less food relevant words to play with
s <- svd(mtx)
rank = 1:12
p = s$v[,rank]
projected = mtx %*% p
## filter out compound words
altmtx = mtx[projected[,2]>0,]
s <- svd(altmtx)
p = s$v[,rank]
projected = altmtx %*% p
foodish = altmtx[projected[,1] < -.50,]

## let's call our matrix Y -- its what we want to reconsitute
y = mtx
y2 = foodish
## create a custom dimension by taking the line between 
## points for two "opposing" words
#p = y["baked",] - y["fresh",]
## project all points onto it
#fresh.baked = y %*% p
#x=fresh.baked[,1]
#x=x[order(x)]
#names(head(x,10))
#names(tail(x,10))
## solve for the reverse projection where fresh.baked x p2 = y
#p2 = qr.solve(fresh.baked, y)
# recalculate original matrix using this single dimension and
# calculate residual error
#yhat = fresh.baked %*% p2
#resid = y - yhat
#sum(resid^2)


## create a custom dimension by taking the line between 
## points for two "opposing" words, or better yet, two sets of
## opposing words. Then bundle those dimensions into a matrix 
## to form a projection matrix.

pmtx = cbind(
  meatiness = (mtx["beef",]+mtx["chicken",]+mtx["pork",]-
    mtx["vegetables",]-mtx["fruit",]-mtx["bread",]),
  sweetness = (mtx["pudding",]+mtx["cake",]+mtx["fruit",]-
    mtx["soup",]-mtx["burger",]-mtx["vegetables",]),
  soupiness = (mtx["soup",]+mtx["stew",]+mtx["smoothie",]-
    mtx["bread",]-mtx["steak",]-mtx["cookie",]),
  cooked = (mtx["steak",]+mtx["soup",]+mtx["cake",]-
    mtx["sushi",]-mtx["salad",]-mtx["batter",])
)

## let's call our matrix Y -- its what we want to project and
## then reconsitute
#y = mtx
y=foodish
projected = y %*% pmtx
## let's look at some of thoe words that show up on opposite 
## ends of the spectrum for a given dimension
x=projected[,2]
x=x[order(x)]
names(head(x,10))
names(tail(x,10))

# recalculate original matrix using this projection and
# and a linear solver to find the best reverse projection
# then calculate residual error on our reconstituted matrix
## NOTE: I'm not really sure where to go with this, but the
## lower the residual error, the better our dimensions are at
## capturing the structure. Ideally we'd like orthogonal 
## dimensions that capture a lot of the structure with fewer
## dimensions. We should probably measure the actual level of
## orthogonality in each of our designer dimensions as well. 
p2 = qr.solve(projected, y)
yhat = projected %*% p2
resid = y - yhat
sum(resid^2)

# scatter plot
projected.csv <- data.frame("image"=rownames(projected),projected)
write.csv(file="data-explorer/word-scatter-custom.csv",x=projected.csv,row.names = FALSE)

## On a completely unrelated topic, I had an alternate idea
## for packaging up our food baskets. Rather than packaging up
## and then splitting a large decision tree we can simply package
## up individual "cubes" of 8 foods at a time representing
## our best effort at three reasonable pairings for each of
## those 8 foods (1 of the other seven foods in the cube and
## one for each of the dimensions represented). The goal of the
## cube would be squareness -- each face should be as "square" as 
## possible with opposite edges as parallel as possible. Rectangles
## and romboids would also be ok given distance may not be 
## easy to compare across dimensions. The key idea here is that we
## maximize the distance on one single dimension for each of the 
## good pairings and minimize the distance along the other two 
## dimensions. 
##
## Each cube would give us the potential of randomly providing 
## three good pairings -- one for each of the dimensions, and one
## validation pairing. We would increase variety buy building
## more cubes off line and having the client randomly choose from
## them at runtime. It would give us a decent way to measure the
## performance of each cube and remove poorly performing ones
## from the mix.
##
## For demo sake I'm just going to build a few cubes out of words
## rather than using images, but this function would word just
## as well for images.


## build a function for generating "food cubes" from
## a food matrix and a set of dimensions. This is just
## an initial draft of a function intended to return selections
## of candidate foods that represent "good" pairings for maximizing
## the difference on one of the three dimensions while minimizing
## it on the other two. Each vertex or corner is a food with
## three neighboring corners that represent good dillema pairings.
## This could be a nice way of packaging up our dillemas in 
## future releases.
build.cube = function(m,x,y,z) {
  pts = data.frame(id=rownames(m),x=m[,x],y=m[,y],z=m[,z])
  midpoint = floor(dim(pts)[1]/2)
  ranked = pts %>% 
    mutate(
      xr=rank(x)-midpoint,
      yr=rank(y)-midpoint,
      zr=rank(z)-midpoint) %>%
    mutate(
      tr=abs(xr)+abs(yr)+abs(zr),
      mr=pmin(abs(xr),abs(yr),abs(zr)),
      octant=1*(zr>0)+2*(yr>0)+4*(xr>0)
    )
  
  corners = ranked %>% arrange(octant,mr) %>% group_by(octant) %>% summarize(id=last(id))
  return(as.character(corners$id))
}



## More output for mvp filtered visuals
cube.corners = build.cube(projected,1,2,3)
projected.csv <- data.frame("image"=cube.corners,projected[cube.corners,])
write.csv(file="data-explorer/cube1.csv",x=projected.csv,row.names = FALSE)

cube.corners = build.cube(projected,2,3,4)
projected.csv <- data.frame("image"=cube.corners,projected[cube.corners,])
write.csv(file="data-explorer/cube2.csv",x=projected.csv,row.names = FALSE)





