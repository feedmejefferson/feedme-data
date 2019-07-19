## fastText tag vectors

The glove dictionary didn't have a entries for a lot of our tags. For compound tags (multiword tags), I was breaking them up into multiple tags, but that often didn't make sense because terms like `Bell Pepper` separate into bell and pepper and while pepper is relevant, bell isn't really. 

`fastText` models/dictionaries still seem to be word based, but when building vectors for words that aren't part of the dictionary, they take parts of those words into account. This may still result in the irrelevance issue with terms like bell-pepper, but it's worth trying for now. 

## Install fast text



## write tags to a file

replace all spaces with hyphens to get `fastText` to treat the multi word tags as single entry compound words:

    ./fasttext print-word-vectors models/cc.en.300.bin <tags.txt >tag-vectors.txt


## write titles to a file

use print-sentence-vector for titles, then:

    ./fasttext print-sentence-vectors models/cc.en.300.bin <titles.txt >title-vectors.txt

In this case, the output file doesn't include the sentence as part of the vector line, so we have to load both the title file and the title vector file separately and bind them together to do the lookup. 