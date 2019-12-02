const queryParams = getQueryParams();
const highlight = queryParams["highlight"] && queryParams["highlight"].split(",");

var radius = 400;
var transitionDuration = 0;

// the terms are a bit confusing here -- we're using trees to show
// our less balanced dendograms generated from hierarchical agglomerative
// clustering -- thus the term food clusters even though we're using the
// "tree" layout
var cluster = d3.layout.tree()
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

d3.json(queryParams["data"] || "labeled-food-clusters.json", function(error, tree) {
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
      function(d) { return "rotate(" + (d.x -90) + ")translate(" + d.y + ")"; })
      .select("circle")
      .style("fill", function(d) { return (highlight && highlight.includes(d.value)) ? "red" : d.edited ? "blue" : "orange" })
      .attr("r", function(d) { return (highlight && highlight.includes(d.value)) ? 10 : 4 });

  const hoverSupport = mobileHover((d)=>showImage(d.value),function(d){if(d==root){updateRoot(root.parent)}else{updateRoot(d)}});
  node
    .on("mouseover", function(d) { hoverSupport.onHover(d) })      
    .on("click", function(d) { hoverSupport.onClick(d) });

}

d3.select(self.frameElement).style("height", radius * 2 + "px");

