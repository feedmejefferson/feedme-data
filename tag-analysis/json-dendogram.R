library(jsonlite)

vsplit <- function(df,dimension) {
  if(dimension<1) {
    i = cut(1:nrow(df), 
          labels=c(1,2,3), 
          breaks=quantile(1:nrow(df),probs=c(0,.4,.6,1)),
          include.lowest = TRUE)
    return(list(df[i==1|i==2,],df[i==2|i==3,]))
  } else {
    i = cut(1:nrow(df), 
            labels=c(1,2), 
            breaks=quantile(1:nrow(df),probs=c(0,.5,1)),
            include.lowest = TRUE)
    return(list(df[i==1,],df[i==2,]))
    
  }
}

addBranchToTree <- function(subset, dimension, branch, tree) {
  l = nrow(subset)
  if(l==1) {
    # if the branch is a terminal node, add the node indexed 
    # by it's branch
    tree[as.character(branch)]=rownames(subset)[1]
    return(tree)
  } else {
    # otherwise process the child branches recursively
    sorted = subset[order(subset[,dimension]),]
    split = vsplit(sorted,dimension)
    tree = addBranchToTree(split[[1]],dimension+1,branch*2,tree)
    tree = addBranchToTree(split[[2]],dimension+1,branch*2+1,tree)
    return(tree)
  }
}

projectionToIndexedTree <- function(subset) {
  tree = list()
  tree = addBranchToTree(subset,1,1,tree)
  return(jsonlite::toJSON(tree, auto_unbox = TRUE))
}


create_branch = function(branch, pointer, cluster, values=NULL) {
  if(pointer<0) {
    b = list()
    if(is.null(values)) {
      b[as.character(branch)] = clusters$labels[-pointer]
    } else {
      b[as.character(branch)] = list(as.list(values[-pointer,]))
    }
    return(b)
  } else {
    return(append(
      create_branch(branch*2,clusters$merge[pointer,1],cluster,values),
      create_branch(branch*2+1,clusters$merge[pointer,2],cluster,values)
    ))
  }
}
clusterToIndexedTree = function(cluster, values=NULL) {
  return(jsonlite::toJSON(
    create_branch(1, nrow(clusters$merge), clusters, values),
    auto_unbox = TRUE))
}




