const getQueryParams = () => {
  const qp = {};
  window.location.search
  .replace(/\?/,"")
  .split("&")
  .map(x => x.split("="))
  .filter(x => x && Array.isArray(x) && x.length === 2)
  .forEach(pair => qp[decodeURIComponent(pair[0])]=decodeURIComponent(pair[1]));
  return qp;  
}

const setQueryParams = (qp) => {
  if (history.replaceState) {
    const queryString = !(qp && Object.keys(qp).length > 0) ? "" :
      "?" + Object.keys(qp)
      .map(key => (encodeURIComponent(key) + "=" + encodeURIComponent(qp[key])))
      .join("&");
    var newurl = window.location.protocol + "//" + window.location.host + window.location.pathname + queryString;
    window.history.replaceState({path:newurl},'',newurl);
  }
}

const formatTags = (tags) => {
  return ((tags && Array.isArray(tags)) ? tags.join(", ") : "")
}

const showImage = (foodId) => {
  const img = $("#image-container img")
  img.attr("src", "/assets/images/" + foodId + ".jpg");
  $.ajax({
    dataType: "json",
    url: "/assets/meta/foods/" + foodId,
    success: function(data) {
      var attr = `<a href="${data.originUrl}" target="_blank" rel="noopener noreferrer">${data.originTitle}</a>` + 
      (data.author ? ` by <a href="${data.authorProfileUrl}" target="_blank" rel="noopener noreferrer">${data.author}</a>` : "");
      $("#title").html(data.title);
      $("#image-attributions").html(attr);
      $("#is-tags").html(formatTags(data.isTags));
      $("#contains-tags").html(formatTags(data.containsTags));
      $("#other-tags").html(formatTags(data.descriptiveTags));
      $("#edit-link").html(`Editor link: <a href="https://feedme-moderator.firebaseapp.com/food/${foodId}" target="_blank">${foodId}</a>`);
    }
  });
}

const showTag = (tag) => {
  $("#title").html(`<a href="https://feedme-moderator.firebaseapp.com/tags/${tag}" target="_blank" rel="noopener noreferrer">${tag}</a>`);
} 

function convertBranch(branch, tree) {
  var b = { }
  if(tree[branch]) {
    b = (typeof tree[branch] === 'object') ? {...tree[branch]} : {value: tree[branch]}; 
    delete(tree[branch]);
  } else {
    const children = [convertBranch(branch*2, tree), convertBranch(branch*2+1, tree)]
    var middleChild = children[0];
    while(middleChild.children) {
      middleChild = middleChild.children[1];
    }
    b = {...middleChild, children};
    // accumulate the size
    b.size = children[0].size + children[1].size
  }
  return(b);
}

const mobileHover = (hoverFunction, clickFunction) => {
  var hovered;
  var locked;
  return {
    onHover: (id) => { 
      if(locked) { return }
      hovered = id;
      hoverFunction(id); 
    },
    onClick: (id) => { 
      if(hovered===id) {
        locked=id;
        clickFunction(id);
      } else {
        locked=null;
        hovered=id;
        hoverFunction(id);
      }
    }
  }
}

const buildFilterFunction = (data, dimensions) => {  
  var filters = [];
  const queryParams = getQueryParams();
  dimensions.forEach(dim => {
    if(queryParams[dim]) {
      const qp = queryParams[dim].split(",").map(x=>+x);
      filters.push({
        scale: d3.scale.linear()
        .range([0,100])
        .domain(d3.extent(data, function(d) { return +d[dim]; })),
        min: qp[0],
        max: qp[1],
        dim
      });
    }
  });
  const limit = queryParams["sample"] && queryParams["sample"] / 100;
  const sample = limit ? () => { return (Math.random() < limit) } : () => true;
  return (d) => sample() && filters.every(f => !(f.min < f.scale(d[f.dim]) && f.max > f.scale(d[f.dim])));
}
