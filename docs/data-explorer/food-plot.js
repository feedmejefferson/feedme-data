
var transitionTime = 2000;

var margin = {top: 20, right: 20, bottom: 60, left: 80},
    width = 600 - margin.left - margin.right,
    height = 600 - margin.top - margin.bottom;

var x = d3.scale.linear()
    .range([0, width]);

var y = d3.scale.linear()
    .range([height, 0]);

//var color = d3.scale.category10();
var color = d3.scale.linear()
  .range(["blue", "orange"]);
//var size = d3.scale.linear()
  //.range([2,10]);

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

var outerSvg = d3.select("div#food-plot")
    .append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom);
var svg = outerSvg.append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

d3.csv("food-plot.csv", function(error, data) {
  if (error) throw error;

  var availableDimensions = Object.keys(data[0]);
  // get rid of the first element which will always be the image name
  availableDimensions.shift();
  // similarly get rid of the last element which is the edited flag for coloring points
  availableDimensions.pop();

  var xDims = svg.append("g").attr("class","x-dimensions")
      .selectAll("text")
      .data(availableDimensions)
      .enter().append("text")
      .attr("class", function(d) {return d;})
      .attr("y", function(d, i) {return height + 60;})
      .attr("x", function(d, i) {return (i+1) * height/(availableDimensions.length+1);})
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

    data.forEach(function(d) {
      d.edited = d.edited == "TRUE" ? 0 : 1;
    });

  color.domain(d3.extent(data, function(d) { return d.edited; })).nice();
//  size.domain(d3.extent(data, function(d) { return d.P; })).nice();

  var points = svg.selectAll(".dot")
        .data(data)
      .enter().append("circle")
        .attr("class", "dot")
        //.attr("r", function(d) { return size(d.P); })
        .attr("r", function(d) { return 4; })
        .on("mouseover", function(d) {      
            img.attr("src", "/images/images/" + d.image + ".jpg");
            $.ajax({
              dataType: "json",
              url: "/images/photos/" + d.image + ".json",
              success: function(data) {
                var attr = `<a href="${data.originUrl}">${data.originTitle}</a>` + 
                (data.author ? `by <a href="${data.authorProfileUrl}">${data.author}</a>` : "");
                $("#title").html(data.title);
                $("#image-attributions").html(attr);
                $("#is-tags").html(data.isTags ? data.isTags.join(", ") : "");
                $("#contains-tags").html(data.containsTags ? data.containsTags.join(", ") : "");
                $("#other-tags").html(data.descriptiveTags ? data.descriptiveTags.join(", ") : "");
                $("#edit-link").html(`Editor link: <a href="https://feedme-stage.firebaseapp.com/photos/${d.image}.jpg" target="_blank">${d.image}</a>`);
              }
            });
            // $.ajax({
            //   dataType: "json",
            //   url: "/images/photos/" + d.image.replace(/jpg/, "json"),
            //   success: function(data) {
            // //          console.log(data);
            //     $("#is-tags").html(JSON.stringify(data.isTags));
            //     $("#contains-tags").html(JSON.stringify(data.containsTags));
            //     $("#other-tags").html(JSON.stringify(data.descriptiveTags));
            //     $("#title").html(data.title);
            //     $("#edit-link").html(`<a href="https://feedme-stage.firebaseapp.com/photos/${d.image}">${d.image}</a>`);
            //   }
            // })
          })   
        .style("fill", function(d) { return color(d.edited); });

  function plot(xDim, yDim) {

    // update the axis links with the new dimensions  
    d3.selectAll(".current").classed("current",false);
    d3.selectAll(".x-dimensions ." + xDim)
      .classed("current",true);
    d3.selectAll(".y-dimensions ." + yDim)
      .classed("current",true);

    xDims.on("click", function(d) {plot(d,yDim);});   
    yDims.on("click", function(d) {plot(xDim,d);});   

    data.forEach(function(d) {
      d[xDim] = +d[xDim];
      d[yDim] = +d[yDim];
    });

    // update the plot scales
    x.domain(d3.extent(data, function(d) { return d[xDim]; })).nice();
    y.domain(d3.extent(data, function(d) { return d[yDim]; })).nice();

    xA.transition().duration(transitionTime).call(xAxis);
    yA.transition().duration(transitionTime).call(yAxis);

    points.transition().duration(transitionTime)
        .attr("cx", function(d) { return x(d[xDim]); })
        .attr("cy", function(d) { return y(d[yDim]); });

  }
  plot("X1", "X2");


});


