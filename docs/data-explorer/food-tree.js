var radius = 400;
var transitionDuration = 0;

// the terms are a bit confusing here -- we're using trees to show
// our less balanced dendograms generated from hierarchical agglomerative
// clustering -- thus the term food clusters even though we're using the
// "tree" layout
var cluster = d3.layout.cluster()
    .size([360, radius - 120]);

var diagonal = d3.svg.diagonal.radial()
    .projection(function(d) { return [d.y, d.x / 180 * Math.PI]; });

var svg = d3.select("#svg-container").append("svg")
    .attr("width", radius * 2)
    .attr("height", radius * 2)
    .append("g")
    .attr("transform", "translate(" + radius + "," + radius + ")");

var img = d3.select("#image-container")
    .append("img")
    .attr("height","300px")
    .attr("src","");


// convert our custom indexed binary tree format to a standard 
// node with children structure that d3 understands
function convertBranch(branch, tree) {
  var b = { }
  if(tree[branch]) {
//    console.log(branch);
    b.value = tree[branch]; 
    delete(tree[branch]);
  } else {
    b.children = [convertBranch(branch*2, tree), convertBranch(branch*2+1, tree)]
    var middleChild = b.children[0];
    while(middleChild.children) {
      middleChild = middleChild.children[1];
    }
    b.value = middleChild.value;
  }
  return(b);
}

d3.json("food-tree.json", function(error, tree) {
  if (error) throw error;
  // I wish I didn't have to fully mutate the tree object, but it seems to be bound
  // to d3 already and replacing it with another object doesn't work
  b = convertBranch(1,tree)
  tree.value=b.value;
  tree.children=b.children;
  updateRoot(tree);
});

//d3.json("clusters.json", function(error, root) {
function updateRoot(root) {
  var nodes = cluster.nodes(root);

  var link = svg.selectAll("path.link")
      .data(cluster.links(nodes));
  link.exit().remove();
  link.enter().append("path")
      .attr("class", "link")
      .attr("d", diagonal);
  link.transition().duration(transitionDuration).attr("d", diagonal);

  var node = svg.selectAll("g.node").data(nodes);
  
  // remove extra elements leftover from before and no longer needed
  node.exit().remove();

  // add new elements if needed
  var enteredNodes = node.enter().append("g")
      .attr("class", "node");
  enteredNodes
      .append("circle")
      .attr("r", 4);
  
  // update all existing ones with details from new data bound to them
  node.transition().duration(transitionDuration)
    .attr("transform",
      function(d) { return "rotate(" + (d.x -90) + ")translate(" + d.y + ")"; });

  node
    .on("click", function(d) {if(d==root){updateRoot(root.parent)}else{updateRoot(d)}})
    .on("mouseover", function(d) {
      img.attr("src", "/images/images/" + d.value + ".jpg");
      //img.attr("src", "http://www.feedmejefferson.com/images/thumbs/" + d.names[1]);
      $.ajax({
        dataType: "json",
        url: "/images/photos/" + d.value + ".json",
        success: function(data) {
          var attr = `<a href="${data.originUrl}">${data.originTitle}</a>` + 
          (data.author ? `by <a href="${data.authorProfileUrl}">${data.author}</a>` : "");
          $("#title").html(data.title);
          $("#image-attributions").html(attr);
          $("#is-tags").html(data.isTags ? data.isTags.join(", ") : "");
          $("#contains-tags").html(data.containsTags ? data.containsTags.join(", ") : "");
          $("#other-tags").html(data.descriptiveTags ? data.descriptiveTags.join(", ") : "");
          $("#edit-link").html(`Editor link: <a href="https://feedme-stage.firebaseapp.com/photos/${d.value}">${d.value}</a>`);
        }
      });

    });

}

d3.select(self.frameElement).style("height", radius * 2 + "px");

