## fastText tag vectors

The glove dictionary didn't have a entries for a lot of our tags. For compound tags (multiword tags), I was breaking them up into multiple tags, but that often didn't make sense because terms like `Bell Pepper` separate into bell and pepper and while pepper is relevant, bell isn't really. 

`fastText` models/dictionaries still seem to be word based, but when building vectors for words that aren't part of the dictionary, they take parts of those words into account. This may still result in the irrelevance issue with terms like bell-pepper, but it's worth trying for now. 

## Install fast text

I probably should have installed a tagged release version, but at the time I just cloned and installed from the master branch. 

That is/was commit 40a77442a756ab160ae3465b26322f6e480405d9

So, from the directory that contains this project (three folders up)

```
git clone https://github.com/facebookresearch/fastText.git
cd fastText
make
mkdir models
cd models
wget https://dl.fbaipublicfiles.com/fasttext/vectors-crawl/cc.en.300.bin.gz
gunzip cc.en.300.bin.gz
```

Then from this directory, simlink over the fasttext executable and the english vocabulary that you just downloaded.

```
ln -s ../../../fastText/fasttext
ln -s ../../../fastText/models/cc.en.300.bin
```

## write tags to a file

remove all spaces to get `fastText` to treat the multi word tags as single entry compound words:

    ./fasttext print-word-vectors cc.en.300.bin <tags.txt >tag-vectors.txt

> Note: originally I tried replacing spaces with hyphens, but I found that the hyphens were introducing too much of their own meaning and words with hyphens were showing up as their own cluster of similar words that had too much similarity with each other even if they were unrelated.

## write titles to a file

use print-sentence-vector for titles, then:

    ./fasttext print-sentence-vectors cc.en.300.bin <titles.txt >title-vectors.txt

In this case, the output file doesn't include the sentence as part of the vector line, so we have to load both the title file and the title vector file separately and bind them together to do the lookup. 
