const queryParams = getQueryParams();
const highlight = queryParams["highlight"] && queryParams["highlight"].split(",");
const initialXdim = queryParams["x"] || "X2";
const initialYdim = queryParams["y"] || "X3";
const initialZdim = queryParams["z"];
const hoverSupport = mobileHover((d)=>showImage(d.image),() => {})

var transitionTime = 2000;

var margin = {top: 20, right: 20, bottom: 60, left: 80},
    width = 600 - margin.left - margin.right,
    height = 600 - margin.top - margin.bottom;

var x = d3.scale.linear().range([0, width]);
var y = d3.scale.linear().range([height, 0]);
var z = initialZdim && d3.scale.linear().range(["blue","white","orange"])

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

var img = d3.select("#image-container")
    .append("img")
    .attr("height","300px")
    .attr("src","");

var outerSvg = d3.select("div#scatter-plot")
    .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom);
var svg = outerSvg.append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

d3.csv(queryParams["data"] || "food-plot.csv", function(error, data) {
  if (error) throw error;

  var availableDimensions = Object.keys(data[0]);
  // get rid of the first element which will always be the image name
  availableDimensions.shift();

  var xDims = svg.append("g").attr("class","x-dimensions")
      .selectAll("text")
      .data(availableDimensions)
      .enter().append("text")
      .attr("class", function(d) {return d;})
      .attr("y", function(d, i) {return height + 60;})
      .attr("x", function(d, i) {return (i+1) * width/(availableDimensions.length+1);})
      .text(function(d, i) {return d;});

  var yDims = svg.append("g").attr("class","y-dimensions")
      .selectAll("text")
      .data(availableDimensions)
      .enter().append("text")
      .attr("class", function(d) {return d;})
      .attr("x", function(d, i) {return -60;})
      .attr("y", function(d, i) {return (i+1) * height/(availableDimensions.length+1);})
      .text(function(d, i) {return d;});

  var xA = svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")");

  var yA = svg.append("g")
        .attr("class", "y axis");


  const applyFilters = buildFilterFunction(data, availableDimensions);

  var points = svg.selectAll(".dot")
        .data(data)
        .enter().append("circle")
        .filter(function(d) { return applyFilters(d) })
        .attr("class", "dot")
        //.attr("r", function(d) { return size(d.P); })
        .attr("r", function(d) { return (highlight && highlight.includes(d.image)) ? 10 : 4; })
        .on("mouseover", function(d) { hoverSupport.onHover(d) })      
        .on("click", function(d) { hoverSupport.onClick(d) })      
        .style("fill", function(d) { return (highlight && highlight.includes(d.image)) ? "red" : "blue" });

  function plot(xDim, yDim, zDim) {

    // update the axis links with the new dimensions  
    d3.selectAll(".current").classed("current",false);
    d3.selectAll(".x-dimensions ." + xDim)
      .classed("current",true);
    d3.selectAll(".y-dimensions ." + yDim)
      .classed("current",true);

    xDims.on("click", function(d) {plot(d,yDim,zDim);});   
    yDims.on("click", function(d) {plot(xDim,d,zDim);});   

    data.forEach(function(d) {
      d[xDim] = +d[xDim];
      d[yDim] = +d[yDim];
      d[zDim] = +d[zDim];
    });

    // update the plot scales
    x.domain(d3.extent(data, function(d) { return d[xDim]; })).nice();
    y.domain(d3.extent(data, function(d) { return d[yDim]; })).nice();
    const extent = d3.extent(data, function(d) { return d[zDim]});
    const median = d3.median(data, function(d) { return d[zDim]});

    z && z.domain([extent[0],median,extent[1]]);

    xA.transition().duration(transitionTime).call(xAxis);
    yA.transition().duration(transitionTime).call(yAxis);

    points.transition().duration(transitionTime)
        .attr("cx", function(d) { return x(d[xDim]); })
        .attr("cy", function(d) { return y(d[yDim]); })
        .style("fill", function(d) { return (highlight && highlight.includes(d.image)) ? "red" : z ? z(d[zDim]) : "blue" });

  }
  plot(initialXdim, initialYdim, initialZdim);


});


