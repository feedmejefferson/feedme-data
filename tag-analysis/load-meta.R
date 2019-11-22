##
## Before you run this, make sure you update the dictionary files
## using the build-fasttext-vectors.R script and the CLI fasttext
## tool
##

cannonicalize_title = function(title) {
  title
}

cannonicalize_tag = function(tag) {
  return(gsub("^$", "_no_tags",gsub(" ", "", tolower(tag))))
}


load_meta_folder = function(folder) {
  fs::dir_ls(folder, regexp = "\\.jpg$") %>%
    map_dfr(ndjson::stream_in) %>%
    gather("tag.type", 
           "tag", 
           -c(id, title, 
              originTitle, originUrl, 
              author, authorProfileUrl, 
              license, licenseUrl)) %>%
    mutate(tag.type=gsub("\\..*$", "", tag.type), 
           original.tag=tolower(tag),
           tag=cannonicalize_tag(tag),
           id=gsub(".jpg","",id),  ## remove legacy extensions if present
           title=cannonicalize_title(title)) %>%
    filter(!is.na(tag)) 
}

load_moderator_foods = function(folder) {
  fs::dir_ls(folder, type="file") %>%
    map(readr::read_file) %>% 
    map(~ str_replace_all(pattern="\n", replacement="",string=.x)) %>%
    map_dfr(ndjson::flatten) %>%
    gather("tag.type", 
           "tag", 
           -c(id, title, 
              originTitle, originUrl, 
              updated, edited, 
              author, authorProfileUrl, 
              license, licenseUrl)) %>%
    mutate(tag.type=gsub("\\..*$", "", tag.type), 
#           original.tag=tolower(tag),
           tag=cannonicalize_tag(tag),
#           id=gsub(".jpg","",id),  ## remove legacy extensions if present
           title=cannonicalize_title(title)) %>%
    filter(!is.na(tag)) 
}

load_title_vectors = function() {
  ## read in the title names and vectors
  ## using a delimiter of ~ because I don't expect it to be in a title
  ## TODO: find a better way not using read_delim
  titles = read_delim("./fasttext/titles.txt", "~", col_names = FALSE)
  title_vectors = read_delim("./fasttext/title-vectors.txt", " ", col_names = FALSE)
  
  ## remove last junk column (there should only be 300 columns, but
  ## every line in the file seems to end with a delimiter)
  title_vectors = title_vectors[,1:300]
  
  ## attach the titles from the original file so that we know
  ## what title the vector is for
  title_vectors$title = titles$X1
  title_vectors = title_vectors %>% distinct_all()
  return(title_vectors)
  
}

load_tag_vectors = function() {
  tag_vectors = read_delim("./fasttext/tag-vectors.txt", " ", col_names = FALSE)
  ## drop the junk column at the end and rename the first column
  tag_vectors = tag_vectors[,1:301]
  colnames(tag_vectors)[1] <- "tag"
  return(tag_vectors)
}

normalize = function(x) {
  ## lets assume x is a dataframe with n rows, one label column
  ## and 300 numeric columns representing a 300 dimension vector
  df = x %>% ungroup()
  label = df %>% select(-starts_with("X"))
  vectors = df %>% select(starts_with("X"))
  mtx = as.matrix(vectors)
  mags = sqrt(rowSums(mtx^2))
  mtx = mtx/mags
  return(data.frame(label[,1],as.data.frame(mtx)))
}

# simlar to normalize, but leaves 0 length vectors 0 rather 
# than turning them into NaN vectors. Similarly it treats NA
# as 0 so it's forgiving for missing values. 
normalize0 = function(x) {
  df = x %>% ungroup()
  label = df %>% select(-starts_with("X"))
  vectors = df %>% select(starts_with("X"))
  mtx = as.matrix(vectors)
  mags = sqrt(rowSums(mtx^2))
  mtx = mtx/mags
  mtx[is.nan(mtx)] = 0
  mtx[is.na(mtx)] = 0
  return(data.frame(label,as.data.frame(mtx)))
}

nn = function(z){names(z)[order(z)[2:6]]}

