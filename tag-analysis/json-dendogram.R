library(jsonlite)

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

