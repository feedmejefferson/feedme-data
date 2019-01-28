library(rjson)

#convert output from hclust into a nested JSON file

HCtoJSON<-function(hc){
  
  labels<-hc$labels
  merge<-data.frame(hc$merge)
  
  for (i in (1:nrow(merge))) {
    
    if (merge[i,1]<0 & merge[i,2]<0) {eval(parse(text=paste0("node", i, "<-list(name=\"node", i, "\", children=list(list(name=labels[-merge[i,1]]),list(name=labels[-merge[i,2]])))")))}
    else if (merge[i,1]>0 & merge[i,2]<0) {eval(parse(text=paste0("node", i, "<-list(name=\"node", i, "\", children=list(node", merge[i,1], ", list(name=labels[-merge[i,2]])))")))}
    else if (merge[i,1]<0 & merge[i,2]>0) {eval(parse(text=paste0("node", i, "<-list(name=\"node", i, "\", children=list(list(name=labels[-merge[i,1]]), node", merge[i,2],"))")))}
    else if (merge[i,1]>0 & merge[i,2]>0) {eval(parse(text=paste0("node", i, "<-list(name=\"node", i, "\", children=list(node",merge[i,1] , ", node" , merge[i,2]," ))")))}
  }
  
  eval(parse(text=paste0("JSON<-toJSON(node",nrow(merge), ")")))
  
  return(JSON)
}

HCtoJSON2<-function(hc){
  
  labels<-hc$labels
  merge<-data.frame(hc$merge)
  
  for (i in (1:nrow(merge))) {
    
    if (merge[i,1]<0 & merge[i,2]<0) {eval(parse(text=paste0("node", i, "<-list(name=labels[-merge[i,1]], children=list(list(name=labels[-merge[i,1]]),list(name=labels[-merge[i,2]])))")))}
    else if (merge[i,1]>0 & merge[i,2]<0) {eval(parse(text=paste0("node", i, "<-list(name=labels[-merge[i,2]], children=list(node", merge[i,1], ", list(name=labels[-merge[i,2]])))")))}
    else if (merge[i,1]<0 & merge[i,2]>0) {eval(parse(text=paste0("node", i, "<-list(name=labels[-merge[i,1]], children=list(list(name=labels[-merge[i,1]]), node", merge[i,2],"))")))}
    else if (merge[i,1]>0 & merge[i,2]>0) {eval(parse(text=paste0("node", i, "<-list(name=node", merge[i,1], "[['name']], children=list(node",merge[i,1] , ", node" , merge[i,2]," ))")))}
  }
  
  eval(parse(text=paste0("JSON<-toJSON(node",nrow(merge), ")")))
  
  return(JSON)
}

HCtoJSON3<-function(hc){
  
  labels<-hc$labels
  merge<-data.frame(hc$merge)
  for (i in (1:nrow(merge))) {
    
    if (merge[i,1]<0 & merge[i,2]<0) {eval(parse(text=paste0("node", i, "<-list(name=labels[-merge[i,1]], count=2, children=list(list(name=labels[-merge[i,1]]),list(name=labels[-merge[i,2]])))")))}
    else if (merge[i,1]>0 & merge[i,2]<0) {eval(parse(text=paste0("node", i, "<-list(name=labels[-merge[i,2]], count=node", merge[i,1], "[['count']]+1, children=list(node", merge[i,1], ", list(name=labels[-merge[i,2]])))")))}
    else if (merge[i,1]<0 & merge[i,2]>0) {eval(parse(text=paste0("node", i, "<-list(name=labels[-merge[i,1]], count=node", merge[i,2], "[['count']]+1,children=list(list(name=labels[-merge[i,1]]), node", merge[i,2],"))")))}
    else if (merge[i,1]>0 & merge[i,2]>0) {eval(parse(text=paste0("if (node", merge[i,1], "[['count']] < node", merge[i,2], "[['count']]) tempname=node", merge[i,1], "[['name']] else tempname=node", merge[i,2], "[['name']]")))
      #}
    #else if (merge[i,1]>0 & merge[i,2]>0) {
    eval(parse(text=paste0("node", i, "<-list(name=tempname, count=node", merge[i,1], "[['count']]+node", merge[i,2], "[['count']],children=list(node",merge[i,1] , ", node" , merge[i,2]," ))")))}
  }
  
  eval(parse(text=paste0("JSON<-toJSON(node",nrow(merge), ")")))
  
  return(JSON)
}

HCtoJSON4<-function(hc){
  
  labels<-hc$labels
  merge<-data.frame(hc$merge)
  
  for (i in (1:nrow(merge))) {
    
    if (merge[i,1]<0 & merge[i,2]<0) {eval(parse(text=paste0("node", i, "<-list(name=labels[-merge[i,1]], first=labels[-merge[i,1]], last=labels[-merge[i,2]], children=list(list(name=labels[-merge[i,1]]),list(name=labels[-merge[i,2]])))")))}
    else if (merge[i,1]>0 & merge[i,2]<0) {eval(parse(text=paste0("node", i, "<-list(name=node", merge[i,1], "[['last']], first=node", merge[i,1], "[['first']], last=labels[-merge[i,2]], children=list(node", merge[i,1], ", list(name=labels[-merge[i,2]])))")))}
    else if (merge[i,1]<0 & merge[i,2]>0) {eval(parse(text=paste0("node", i, "<-list(name=labels[-merge[i,1]], first=labels[-merge[i,1]], last=node", merge[i,2], "[['last']], children=list(list(name=labels[-merge[i,1]]), node", merge[i,2],"))")))}
    else if (merge[i,1]>0 & merge[i,2]>0) {eval(parse(text=paste0("node", i, "<-list(name=node", merge[i,1], "[['last']], first=node", merge[i,1], "[['first']], last=node", merge[i,2], "[['last']], children=list(node",merge[i,1] , ", node" , merge[i,2]," ))")))}
  }
  
  eval(parse(text=paste0("JSON<-toJSON(node",nrow(merge), ")")))
  
  return(JSON)
}

HCtoJSON5<-function(hc){
  
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



