# Food Baskets

> Note, I'm moving all of this actual implementation over to a javascript project. After a lot of back and forth on how to implement it (as you can see from the notes below), I've decided that it makes more sense to implement this in a javascript library since I'll ultimately have to write the code that reads in all of the baskets and puts them back together again as javascript. Building the code that does both in a single library will make it a little bit easier to  1. test and 2. include in multiple projects (feed me jefferson, data explorers, server side functions...)

## Background Thoughts and Notes

> Note: take all of this with a grain of salt. I'm still pretty novice on the front end development side and I think I need to take some time and go learn some of the basics regarding `workbox`, `service workers`, `webpack` and `bundles`. I think `bundles` in particular probably overlap with the whole concept of baskets that I'm trying to support here. 

With Adams Apple I tried to introduce the concept of a food basket. It all started with partial tree/indexes. I thought it would be nice if we could support shipping minimal chunks of the food world that could be expanded on demand based on the users tastes. Ideally the core basket would include a nice diverse set of foods that catered to all tastes, and then as a user showed interest in certain types of foods, we would be able to _zoom them in_ to that area of the food world and expand their core basket. 

Our food tree/index has kind of settled on a binary decision tree that caters to the user choosing one of two branches based on an image of food that represents each branch. One of the trickiest parts of this is choosing a single food to represent a branch that may include hundreds of images of food -- what if we choose the wrong food to represent the branch? Or what if we choose the perfect foods, but they're always the same? Would that get boring?

We've explored a few different approaches for adding in variety randomly choosing an image from each of the branches, but this in itself requires having more than one image available at the time that we flip the so called coin. Our goal is to find the right balance between preloading enough offline content to offer variety without preloading too much content to blow the devices memory/data plan. 

## Possible Feature: Customizable Baskets

It would be really nice if users could create their own personalized baskets of food that they like from pictures that they took themselves. That way you could put together a custom selection of your own typical _go to_ food choices that you already know how to cook, or from restaurants that you already know you like. 

## Basket Contents

Obviously every basket of food contains a number of food items... Each food item is currently comprised of:

* image
* index (location in decision tree)
* attribution metadata
* food location in vector space (if we have multiple projections, this would depend on the space representation)
* food tags (currently these are the main source of determining where the food falls in the food space)

We could put all of the metadata into the same file, but we don't actually use the tags for anything on the client side just yet and they can get a bit bulky, so we may want to split up the metadata and package it separately for different purposes -- and some metadata we might not want to package at all.

## Basket Naming

Each basket should contain a specific set of food items. Given that we might bundle up different combinations of overlapping food items for different purposes, it would be nice if we had some fairly deterministic way of naming our baskets -- hashing seems like a useful idea, the question is what to hash on? The full set of content? Or just the ids? The full content might be the best choice since it would make the name/content connection immutable -- so for caching purposes, if you have the file, you have the file and it never needs to be updated (if it does, it would have a different name). However, this does mean that the name itself can't be part of the contents of the file... Alternatively we might want the name to be based purely on the combination of food items that it contains rather than the meta data about those items.

## Basket Item Selection

So how do we select which food items end up in a basket? 

The original idea was to use baskets as a way to expand branches as the user clicks their way through the decision tree. In that case, a basket simply represents a branch and contains the contents of that branch to the extent that the number of items contained in the branch doesn't exceed the maximum basket size. If the branch contents exceed the maximum basket size, then we need to break the branch into more baskets. This is where we probably want to balance a few goals:

* really small baskets seem like a bad thing
* baskets should cover the full variety of the branch that they represent
* data size probably matters more than number of items (within reason)

To put this in perspective, if we have a maximum basket size of 64 food items, and we have a branch with 65 food items in it, it would be kind of silly/inefficient to create a basket with 64 and another basket of 2 items (having to arbitrarily come up with one of the two items to represent the basket of two and then save it twice...). In this example, I think it would probably make sense just to create one basket with 65 items. On the other hand, if we had 257 items and a maximum basket size of 256... We do have to draw the line somewhere. Rather than having hard maximums, it probably makes sense to have target ranges.

To give a different example, if we decide to support highly imbalanced decision trees -- ones that have some long and spindly branches, but other short and quickly terminating ones (such as the example below), we wouldn't want to split the main branch in half vertically (or horizontally based on the sideways tree representation) -- as in we wouldn't want to separate it into one basket for branch `2` and another for branch `3`, but rather we would want to go through a breadth first decent and break it off at branches `9` and `6`, finding representative food items for each of those branches so as to provide a fairly well balanced set of options.

> This does bring up an interesting point though -- what if we end up with a lot of small baskets for each of the spindly branches (or even just the outer edge of a large balanced tree)? Can and should we consolidate them somehow into a basket that can be used to expand multiple branches? I think the answer is yes and I think it helps to answer some of the problems presented with the conflicting goals mentioned above. 


```
1
├── 2
│   ├── 4 
│   │   └── 9
│   │       ├── 18
│   │       │   ├── 36
│   │       │   └── 37
│   │       └── 19 
│   └── 5  
└── 3
    ├── 6  
    │   ├── 12
    │   └── 13
    │       ├── 26 
    │       └── 27 
    └── 7  
```
  

## Basket Representation



## Single vs Multi Branch Baskets

If we take the approach that a basket is linked to a single branch, then we might be tempted to say that each basket elects a single food item to be act as it's best representation (for instance, maybe the centroid food closest to the center, or alternatively it's most or even least popular item). At that point, it might be reasonable to assume that that representative was already available as part of the parent basket that this basket expands. 

However, if we're talking about basket sizes of 64 items, and only one of them is already loaded as part of the parent basket, then maybe this overlap isn't such a big deal. If we're talking about consolidating numerous shorter branch expansions into a single basket though, the overlap would be greater. 

Most of the data volume will come from the images themselves, rather than the metadata about the images, so again, if the baskets aren't redundantly including the image data, then maybe it isn't that important and including redundant data might just make our lives easier. 

As a gut feel, my current instinct is that we'll want to target basket sizes somewhere between 64 and 256. Based on our current typical image size/resolution, 64 images would be about 3mb, so 256 would be about 12mb. That seems like a reasonable payload size target range to me. I also think we'll want to target splits of at least 16 -- meaning if we had a thousand images, we could create a core basket of 64 with 16 consolidated expansion baskets of 64 rather than 64 individual expansion baskets of 8 each. 


## Ulterior Motives

The main motive for expandable trees via expansion baskets is obviously to provide smaller chunks of diverse sets of food that would provide meaningful offline functionality with extendable online finer grain support. 

This does however present us with a conveniently questionable opportunity to collect feedback from the user. We could accomplish most/all of this with prebuilt static indexes and client side logic, or could slip in some dynamic server side logic and use it as an opportunity to log the call. 

> It's all about the analytics...

The fact that a user is asking to expand a branch tells us something about their engagement -- they've been clicking on food, and they've been clicking on the type of food that they want to see more of. Because of the way that we've engineered the site (to work offline, and because somebody else is hosting it), traditional click logs aren't really avaialable to us. We can plug in google analytics, but it will miss some traffic and brings up a slew of privacy questions of it's own. 

Expandable branches provide us with the opportunity to insert a dynamic server side request (we could implement it via a google cloud function) giving us an opportunity to log the interaction ourselves. The function doesn't have to send the entire basket as a payload, it could simply act as the intermediary that maps something like a branch id to a basket id -- as in, I'm getting close to the end of a branch and it doesn't look like it's a terminal node, can you provide me with a basket to expand it?  Sure, you're on branch X, you need basket Y, here's the url, go get it yourself. 

## Basket Format Proposal 1

I'm going to start with something lazy and simple and iterate from there. When I say lazy, I simply mean I'm not going to try to spend too much time trying to figure out how to generate it perfectly in R -- I'll do what I can with jsonlite and leave it up to the javascript code to deal with it for now. 

I'll break the setup into three types of files:

* index -- the tree that maps node address to food id
* attributions -- the title and other attribution metadata
* vector -- the vector map for each food (just an array)

I think I'm going to go back to my original vision for how branch expansion will work. Back then I pictured a bit of a leapfrog concept where each partial file would expand a branch out to a specific depth N, but we would build expansion files for every branch depth that was a multiple of N/2. So to take an example, if we targeted baskets of size 64, that would support a branch depth of 6 (2^6=64). Then every 3(ish) depths we would provide an expansion basket.

Right now the client is responsible for checking if there are expansion packs for any of the terminal nodes on it's branch -- this creates a lot of chatter, and most of it is needless as the user gets close to the true terminal nodes. With consolidated branches, they'd only have to make one call to eagerly expand out a number of branches, the problem is they'd have to know at which branch they should make the call -- and it would be nice if they knew that they didn't have to because there were no more expansions waiting...

This is where our server side function could come in handy -- you pass it a branch number and it tells you the best basket necessary to support it. The client could also be tightly coupled to know this logic, but then updates would require full updates to the client, so using a server side function could be nice for facilitating updateless updates...

Either way, the client side doesn't necessarily have to know the exact basket id for the update, but it would still be good if it atleast knew at which branch it should request an expansion (or that there is an expansion that it can request). This means in addition to the index itself, every branch should somehow communicate a list of available expansions.




##

```
0 -- 1 -- 2 -- 3  -- 4  -- 5  -- 6   (depth)

1 -- 2 -- 4 -- 8  -- 16 -- 32 -- 64  (1st brnch & size)
          5 -- 10 -- 20 -- 40
     3 -- 6 -- 12 -- 24
          7 -- 14 -- 28
               15 --
```


### file names

```
   index.<basket-id>.json
   attributions.<baskekt-id>.json
   vectors.<basket-id>.json
```

### Contents/Format

index.zzz.json

```
{
    "<branch-number>": "<food-id>",
    "<branch-number>": {
      basket:"<basket-id>"
    },
    "<branch-number>": {
      representative:"<food-id>"
    },
    ...
}
```

The index will be an associative array mapping branch numbers to any one of the following:

1. food
2. basket
3. representative (food proxy)

Each (terminal) basket has to choose representatives to pass down to the parent basket -- it may choose not to include them in it's attribution/vector sets.

The goal would be to have the number of foods that a basket has to define be close to some target -- ideally less than twice the target and more than half of it... So for a target of 64, we're saying somewhere between 32 and 128.

If each basket only has to define the actual foods minus the representatives that it is delegating responsibility for down to the parent basket plust the representative foods delegated to it from any of it's child basket, then...

Given the complete tree (not yet broken up), we know that the core central basket will have to include details for all of the terminal nodes that fall within it's _event horizon_ (the ring that would naturally lead to the target size), plus the representatives for each of the nodes on the event horizon (but for a very unbalanced tree, that even horizon might actually extend out further than expected -- a breadth first search would be a good way to handle this). 

So, if we work from the center and run a breadth first search, we should be able to come up with all of the branches that need representatives, we don't necessarily know from that though how to best consolidate the expansion of those representatives into baskets. 




Maybe the index structure for consolidated branches should be an associative array of indexes -- with the branch id to be expanded mapping to it's expansion set?

```
{
  "<branch-number>": {
    "<branch-number>": "<food-id>",
    "<branch-number>": {
      basket:"<basket-id>"
  },
  "<branch-number>": {
      representative:"<food-id>"
    },
    ...
    
    },
    "<branch-number>": {
    
  }
}
```


## Proposed Chunking Algorithm

Use the following inputs:

`targetBasketSize`: the ideal number of foods to include in a basket. The actual number should by no means exceed twice this target, and should ideally always be more than half of it -- so small branches should be consolidated to make up baskets in the target range.

`consolidationEagerness`: we could come up with a better name for this, but it's a dial that reflects a few things:

1. the minimum variety that a user should see -- i.e. the number of possible pairings that a user has the opportunity to see for any food pairing/dilemma. For a balanced tree, this would be `2^(consolidatedEagerness-n)` (`n` having to do with the latency that it takes the client to load the next basket asyncrounously in the background).
2. the overlap between baskets -- how much redundancy do we have in food items between baskets
3. 

> Note, both of these values naturally tend to be related to powers of two because of our binary trees -- is it better to express them as an absolute value, or as the exponent value that two is raised to? Should we be consistent? Essentially it's a question of branch depth vs node count.

For a better understanding of these dials, we should probably look at the two extreme cases -- what are the minimum and maximum possible values for the consolidation eagerness? We could forgo consolidation altogether leaving it up to the client to sometimes preload branches before reaching them (as the earlier implementations of adams apple have done). Conversely, we could maximize the eagerness such that each step expands the tree -- including the initial load. In this case, the minimum user variety would essentially be the same as the maximum user variety. We would have a core syncronously loaded basket that sees the world up to a certain depth, and an asyncronously loaded expansion basket for branch 1 that extends the tree by a depth of 1, providing an alternative proxy food item for each of the items in the core basket (and doubling the size of the main branch itself). After that, every branch would have an expansion pack (until no more were needed), doubling out the size of the branch that the user is on each time they click on a food. This is the most chatty and eager version, but it might also be the easiest version to implement as a start. 

### Step 1: Build the Tree

Just go ahead and build our standard binary tree structure.

### Step 2: Identify the core basket nodes

Perform a breadth first traversal of the tree, maintaining a list (or two) of nodes and replacing them by their child nodes. Each time we increase the depth of the traversal, check the size of the list. If it's larger than the minimum target range, keep track of it as a possible candidate, but continue traversing. We should be guaranteed to find one (or two) candidates that fall within the range, but for unbalanced trees, we may actually find many more.

Optimization: maintain two lists -- one of terminal nodes, one of non terminal nodes. We only need to continue traversing non terminal nodes and at each depth, we know that the minimum size of the next depth will be the total number of nodes and the maximum size of the next depth will be the current number of terminal nodes plus twice the number of non terminal nodes -- __So if the minimum size is greater than the maximum target size, we should stop__.


## New Draft Proposal

Let's keep it as simple as possible. Based on some of the above description, we'll go with the approach where we take the maximum eagerness value and thus every branch has a basket. For now I retract my comments about that meaning that branch one might have a basket separate from the core (maybe there is a basket 0 and that's the core basket, and it's half of the size of the branch 1 basket, but I'm not sure just yet). 

In this case, every branch has a basket (unless that branch has already been fully expanded by a parent branch). Every node also has a representative food and it seems to be the case that bisecting provides us with a very convenient strategy here, because it guarantees us that no branching node has the same representative food. This makes it fairly easy to avoid redundancy as we build out the branches -- and in the worst case we can redundantly resend all terminal nodes in terminal baskets with a redundancy that scales fairly well (big O(n) for the entire set and big O(k) for a single branch). 

So, as a quick and dirty approach that may not generalize well, I propse that we do the same thing that we've been doing for the food explorers -- build the main tree, then build a filled in tree that elects representative foods for every branch node using a bisection approach, then simply build baskets for every branch that has a max depth equal to or less that the log of the target size (or equal to or less than the target depth if we choose to express it that way). 

For now, we will simply use the branch number as the basket id. I'm tempted to leave the branch element definitions out completely in this initial implementation since they'll fill up the tree.

Ugh, now that I think about how to expand the branch using bisection, it seems like that might not be such a good idea. We would want something easily recursive -- so that the food that is chosen to represent a branch that needs to be expanded is also contained in the immediate expansion of that branch. Taking the first or last node from a branch may be the only way to do this.

So... For the first lazy implementation -- create a basket for every branch, make the branch number the basket id, always make the first node the representative node of a branch


two values: basket depth/size, eagerness = depth-1

Run recursively (depth first) 

## Ugh, let's try again

Sorry, I keep hitting a bit of a wall on these and then try to come up with a simpler brute force approach to just power through this. 

A representative branch is a branch that mimics a leaf node by offering a food item that represents all of the foods in that branch. We can build these recursively using a strategy that defines how to chose which of the descendant leaf or representative nodes to elect as the representative (but by saying we only choose from represenatives or unrepresented leaves). For representation we also have to specify a depth or size for the representation strategy.

> I can already see some challenges arising if we don't choose the trivial depth of 1 / size of 2 for representative branches. Suppose we go with a depth of two, do we count back from the leaves, or do we count out from the root? My gut says that the latter would be preferrable meaning we might want to force represtative branches at mods of absolute depth... But I'm probably just getting ahead of myself.


A basket is simply a consolidation of representations. So, literally this might mean that we represent a basket (index) as an array of representation objects. Baskets delegate responsibility for providing representative metadata to their parent basket, and baskets only need to know about their direct child baskets, not their further decedants. 

This all means we end up with three different depths -- the depth from a basket root to its child baskets, the depth from a basket root to it's representative nodes and the depth from representative nodes to the nodes that they represent.

Ok, I think I finally have a plan of attack. Just walk the tree depth first and use a map/reduce style combiner concept to prevent the overhead from ever getting too big. In theory, we never need to maintain more than a baskets worth of information in memory before writing out the basket -- so just collect a baskets worth of data, call a function to write the basket to file, reduce the basket to only the details that need to be passed back to the parent basket and continue. 

The most confusing part here is that we kind of have to maintain a stack or list of representation lists. 

For instance, suppose we want to target baskets of size 32 -- that's two to the fifth, so we could say baskets of depth 5 and we want an eagerness of 3 so that by the time we get down to branches that only have 8 options (2^3) we want to expand the branch, then we're saying that (for a balanced tree) the root basket should have 32 representative nodes and 4 child baskets. Each of those 4 child baskets would itself have 4 child baskets and 32 representative nodes that expand out the 8 representative nodes from that branch of the core basket (assuming we haven't hit any terminal nodes yet). So, we have baskets for branches at depths 0, 2, 4, 6... and representative nodes for branches at depths 5, 7, 9, 11... Now to take the example of an arbitrary branch/node at depth 6, we are within the scope of four baskets -- we should be building one for the branch itself, but also keeping building representatives for branches at depths 5 for inclusion in basket 0 and maintainining the representatives already build for the branches at depth 7 and 9 for basket at depth 2 and 4.


## And so...

That brings us back to this:


```
0 -- 1 -- 2 -- 3  -- 4  -- 5  -- 6   (depth)

1 -- 2 -- 4 -- 8  -- 16 -- 32 -- 64  (1st brnch & size)
          5 -- 10 -- 20 -- 40
     3 -- 6 -- 12 -- 24
          7 -- 14 -- 28
               15 --
```

Let's take Adams Apple with 40 foods and attempt to break it up with a basket depth of 3 and an expansion frequency of 1 meaning representation also of 1 and eagerness of 2 (3-1). 

With a basket depth of 3, there's automatically a fixed set of nodes that are within the scope of the basket -- exactly 15 (2^(3+1)-1). 

Any node other than node 1 can be a leaf (or raw food) node. 

The two nodes at depth 1 (the expansion frequency) are potential basket (reference) nodes, but they will only be basket nodes if there are representation/proxy nodes at depth 3 (specifically node 2 is a basket node if any of nodes 8-11 are proxy nodes and node 3 will if any of the nodes 12-15 are). 

When we serialize a basket, we include **ANY** raw food nodes, but we only include proxy nodes at depth 3 and we only include basket references at depth 1. 

Said from a different perspective, if there are any foods in any nodes at depth 3 (raw or proxy), node 1 becomes a basket. We serialize the basket which means we build an index with all raw foods, proxy foods in depth 3 nodes and basket references in depth 1 nodes. 

let's take another simple and extreme example:

```
0 - 1 - 2 - 3    (depth)

1 - 2 - 4 - 8 - 16 - 32
  \   \   \   \    \
    3   5   9   17   33
```

This is a very spindly basket branch. It only has 6 naked foods at nodes 3, 5, 9, 16, 32 and 33. If we used the first child strategy for proxy foods, then 32 would be the proxy all the way down at branches 16, 8, 4, 2 and 1. If we went with a basket depth of 3, we would want to end up with two baskets -- one for branch 1 and one for branch 2. The core basket.1.json would look something like:

```
{
  2: {basket: 2},
  3: "0003",
  5: "0005",
  8: {proxy: "0032"},
  9: "0009"
}
```

basket.2.json would look something like

```
{
  4: {basket: 4},
  16: {proxy: "0032"},
  17: "0017"
}
```

finally, basket.4.json would look like

```
{
  32: "0032",
  33: "0033"
}
```

This shows that examples really help. For some reason I had been thinking that any naked food nodes needed to show up in the baskets, but now I see that it's the opposite -- only the naked food nodes outside of the expansion horizon belong in the basket. 