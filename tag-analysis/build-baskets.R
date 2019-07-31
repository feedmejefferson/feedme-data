## For now assume we're starting with the ending environment 
## from build-food-vectors.R
#source("./build-food-vectors.R")

# convert the tree to a simplified list using json as an
# intermediary... For now this is what we'll assume as the
# starting point format for some of these functions
t = jsonlite::fromJSON(tree)

# write out the basket files
#v = t(projected)
#vectors = split(v, rep(1:ncol(v), each = nrow(v)))
#names(vectors) = gsub(".jpg","",rownames(projected))
#write(jsonlite::toJSON(vectors), "vectors.all.json")

#attributions = meta %>% 
#  select(author, authorProfileUrl, id, license, licenseUrl, originTitle, originUrl) %>%
#  distinct_all() %>% head(3)



split_tree = function(tree, target_size=32) {
  branches = tree
  keys = as.integer(names(branches))
  max.depth = ceiling(log2(max(keys)))
  leaves = list()
  unsolved.brances = 1
  found.leaves = 0
  remaining.keys = keys
  # breadth first search through tree depths
  for(depth in 0:max.depth) {
    cat("\n");cat(depth);cat(": ")
    start = 2^depth
    end = (2^(depth+1))-1
    leaf.keys = which(keys<=end & keys>=start)
    remaining.keys = remaining.keys[!remaining.keys %in% leaf.keys]
    found.leaves = found.leaves + length(leaf.keys)
    leaves = append(leaves, branches[leaf.keys])
    #  cat(length(leaves)); cat("   ");cat(keys[leaf.keys])
    cat(" found: ");cat(length(leaves))
    unsolved.brances = (unsolved.brances - length(leaf.keys)) * 2
    cat(" unsolved: "); cat(unsolved.brances)
    cat(" min size: "); cat(unsolved.brances + length(leaves))
    #  for(node in start:end) {
    #    cat(node); cat(" "); # print every branch number
    #  }
    #  cat("\n")
  }
  
}

split_tree(t)


branch_size = function(tree, branch) {
  if(exists(as.character(branch), where=tree)){
    return(1)
  } else {
    size = branch_size(tree,branch*2)+branch_size(tree,branch*2+1)
    if(size>=8 && size<=16) {
      cat("\nbranch: ");cat(branch);
      cat("    size: ");cat(size);
    }
    return(size)
  }
}

walk_tree = function(tree, branch) {
  depth=floor(log2(branch))
  if(exists(as.character(branch), where=tree)){
    # it's a terminal food node
    nodes = list()
    nodes[as.character(branch)]=tree[as.character(branch)]
    l = list(nodes=nodes,size=1,maxDepth=1,representative=tree[as.character(branch)][[1]])
    return(l)
  } else {
    b1 = walk_tree(tree,branch*2)
    b2 = walk_tree(tree,branch*2+1)
    size = b1$size + b2$size
    representative = b1$representative ## TODO: representative strategy
    maxDepth = max(b1$maxDepth,b2$maxDepth) + 1
    nodes = append(b1$nodes,b2$nodes)
    if(size>=8 && size<=16) {
      cat("\nbranch: ");cat(branch);
      cat("    size: ");cat(size);
      cat("    depth: ");cat(depth);
      cat("    maxDepth: ");cat(maxDepth);
      cat("    rep: ");cat(representative);
    }
    l = list(
      nodes=nodes,
      size=size,
      maxDepth=maxDepth,
      representative=representative)
    return(l)
  }
}
l = walk_tree(t,1)



walk_tree = function(tree, branch) {
  basketDepth=3
  frequency=1
  basket=list()
  depth=floor(log2(branch))
  if(exists(as.character(branch), where=tree)){
    # it's a terminal food node
    nodes = list()
    nodes[as.character(branch)]=tree[as.character(branch)]
    basket[1]=nodes
    l = list(basket=basket,size=1,maxDepth=1,representative=tree[as.character(branch)][[1]])
    return(l)
  } else {
    b1 = walk_tree(tree,branch*2)
    b2 = walk_tree(tree,branch*2+1)
    size = b1$size + b2$size
    representative = b1$representative ## TODO: representative strategy
    maxDepth = max(b1$maxDepth,b2$maxDepth) + 1
    basket = append(b1$basket[1],b2$basket[1])
    if(size>=8 && size<=16) {
      cat("\nbranch: ");cat(branch);
      cat("    size: ");cat(size);
      cat("    depth: ");cat(depth);
      cat("    maxDepth: ");cat(maxDepth);
      cat("    rep: ");cat(representative);
    }
    l = list(
      basket=basket,
      size=size,
      maxDepth=maxDepth,
      representative=representative)
    return(l)
  }
}
l = walk_tree(t,11)

