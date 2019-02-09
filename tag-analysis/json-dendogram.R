library(rjson)

toLabeledJsonNodeTree<-function(hc){
  
  labels<-hc$labels
  merge<-data.frame(hc$merge)
  nodes<-vector("list",nrow(merge))
  
  for (i in (1:nrow(merge))) {
    children <- vector("list",2)
    for(j in (1:2)) {
      if(merge[i,j]<0) {
        label <- labels[-merge[i,j]]
        children[[j]] <- list(names=c(label,label,label,label))
      } else {
        children[[j]] <- nodes[[merge[i,j]]]
      }
    }
    nodes[[i]] <- list(names=c(children[[1]][["names"]][1],children[[1]][["names"]][4],children[[2]][["names"]][1],children[[2]][["names"]][4]),children=children)
  }
  return(toJSON(nodes[[nrow(merge)]]))
}

toJsonNodeArray<-function(hc){
  
  labels<-hc$labels
  merge<-data.frame(hc$merge)
  nodes<-vector("list",nrow(merge))

  for (i in (1:nrow(merge))) {
    cnames <- vector("list",2)
    children <- vector("list",2)
    for(j in (1:2)) {
      if(merge[i,j]<0) {
        label <- labels[-merge[i,j]]
        cnames[[j]] <- list(names=c(label,label,label,label))
        children[[j]] <- NULL
      } else {
        cnames[[j]] <- nodes[[merge[i,j]]]
        children[[j]] <- nrow(merge) - merge[i,j]
      }
    }
    nodes[[i]] <- list(names=c(cnames[[1]][["names"]][1],cnames[[1]][["names"]][4],cnames[[2]][["names"]][1],cnames[[2]][["names"]][4]),children=children)
  }
  return(toJSON(rev(nodes)))
}

toJsonNodeTree<-function(hc){
  
  labels<-hc$labels
  merge<-data.frame(hc$merge)
  nodes<-vector("list",nrow(merge))
  
  for (i in (1:nrow(merge))) {
    children <- vector("list",2)
    for(j in (1:2)) {
      if(merge[i,j]<0) {
        label <- labels[-merge[i,j]]
        children[[j]] <- list(value=label)
      } else {
        children[[j]] <- nodes[[merge[i,j]]]
      }
    }
    nodes[[i]] <- list(children=children)
  }
  return(toJSON(nodes[[nrow(merge)]]))
}

toJsonWeightedTree<-function(hc,values){
  
  labels<-hc$labels
  merge<-data.frame(hc$merge)
  nodes<-vector("list",nrow(merge))
  
  for (i in (1:nrow(merge))) {
    children <- vector("list",2)
    for(j in (1:2)) {
      if(merge[i,j]<0) {
        index <- -merge[i,j]
        value=values$labels[index]
        size=values$counts[index]
        children[[j]] <- list(value=value,size=size)
      } else {
        children[[j]] <- nodes[[merge[i,j]]]
      }
    }
    nodes[[i]] <- list(size=children[[1]][["size"]]+children[[2]][["size"]],children=children)
  }
  return(toJSON(nodes[[nrow(merge)]]))
}


vsplit <- function(df, n=2) {
  l = nrow(df)
  r = l/n
  return(lapply(1:n, function(i) {
    s = max(1, round(r*(i-1))+1)
    e = min(l, round(r*i))
    return(df[s:e,])
  }))
}


buildBalancedLabeledNode <- function(subset, dimension) {
  l = nrow(subset)
  name=c(rownames(subset)[ceiling(l/2)])
  if(l<2) {
    return(list(names=c(name,name)))
  } else {
    sorted = subset[order(subset[,dimension]),]
    children=lapply(vsplit(sorted),function(x) {buildBalancedLabeledNode(x,dimension+1)})
    return(list(names=c(name,name),children=children))
  }
}
buildBalancedNode <- function(subset, dimension) {
  l = nrow(subset)
  if(l<2) {
    return(list(value=rownames(subset)[1]))
  } else {
    sorted = subset[order(subset[,dimension]),]
    children=lapply(vsplit(sorted),function(x) {buildBalancedNode(x,dimension+1)})
    return(list(children=children))
  }
}

pcaToBalancedTree <- function(subset) {
  node=buildBalancedNode(subset,2)
  return(toJSON(node))
}
pcaToBalancedLabeledTree <- function(subset) {
  node=buildBalancedLabeledNode(subset,2)
  return(toJSON(node))
}


