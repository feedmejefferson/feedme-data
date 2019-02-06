var radius = 400;
var transitionDuration = 0;

var cluster = d3.layout.tree()
    .size([360, radius - 120]);

var diagonal = d3.svg.diagonal.radial()
    .projection(function(d) { return [d.y, d.x / 180 * Math.PI]; });

var svg = d3.select("#svg-container").append("svg")
    .attr("width", radius * 2)
    .attr("height", radius * 2)
    .append("g")
    .attr("transform", "translate(" + radius + "," + radius + ")");

d3.json("word-tree.json", function(error, root) {
  if (error) throw error;
  updateRoot(root);
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
  enteredNodes.append("text")
      .attr("dy", ".5em");
  
  // update all existing ones with details from new data bound to them
  node.select("text")
      .attr("text-anchor", function(d) { return d.x < 180 ? "start" : "end"; })
      .attr("transform", function(d) { return d.x < 180 ? "translate(8)" : "rotate(180)translate(-8)"; })
      .attr("font-size", function(d) { return d.size ? Math.pow(d.size,.2) + "em" : "1rem"})
      .text(function(d) { return d.value });

  node.select("circle")
      .attr("r", function(d) { return d.size ? Math.pow(d.size,.3) : 2 });

  node.transition().duration(transitionDuration)
    .attr("transform",
      function(d) { return "rotate(" + (d.x -90) + ")translate(" + d.y + ")"; });

  node
    .on("click", function(d) {if(d==root){updateRoot(root.parent)}else{updateRoot(d)}});

}

d3.select(self.frameElement).style("height", radius * 2 + "px");

