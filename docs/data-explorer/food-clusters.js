var radius = 400;
var transitionDuration = 0;

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

d3.json("food-clusters.json", function(error, root) {
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
  
  // update all existing ones with details from new data bound to them
  node.transition().duration(transitionDuration)
    .attr("transform",
      function(d) { return "rotate(" + (d.x -90) + ")translate(" + d.y + ")"; });

  node
    .on("click", function(d) {if(d==root){updateRoot(root.parent)}else{updateRoot(d)}})
    .on("mouseover", function(d) {
      //img.attr("src", "../images/" + d.names[1]);
      img.attr("src", "http://www.feedmejefferson.com/images/thumbs/" + d.names[1]);
      $.ajax({
        dataType: "text",
        url: "http://www.feedmejefferson.com/images/attributions/" + d.names[1] + ".txt",
        success: function(data) {
          $("#image-attributions").html(data);
        }
      });
      $.ajax({
        dataType: "text",
        url: "http://www.feedmejefferson.com/images/tags/" + d.names[1] + ".txt",
        success: function(data) {
          $("#image-tags").html(data.replace(/,/g, ", "));
        }
      });

    });

}

d3.select(self.frameElement).style("height", radius * 2 + "px");

