## reads in clicks from files in the original log format
library(tidyverse)
library(lubridate)

logs = fs::dir_ls("../raw", 
                  recurse=TRUE, 
                  regexp="2018") %>% 
  map_dfr(function(x) {
    read_delim(x, 
               delim=" ", 
               escape_double=FALSE, 
               col_names=c('host','ident','authuser',
                           'date','time','request',
                           'status','bytes','referrer',
                           'useragent'), 
               col_types = 'cccccccccc',
               trim_ws=TRUE)
    }) %>%
  filter(grepl("hunger.json\\?searchSession",request)) 

## cleanup the datetime and split request URLs into components
logs = logs %>% 
  mutate(bot=grepl("bot", useragent)) %>%
  unite("date",date,time,sep=" ") %>%
  mutate(datetime=parse_date_time(date,"[%d/%b/%Y:%H:%M:%S %z]")) %>%
  mutate(date=date(datetime)) %>%
  mutate(month=floor_date(datetime,unit="month")) %>%
  extract(request, 
          c("session", "chosen", "notChosen", "drop", "hour"), 
          "^.*searchSession\\=([^& ]*)&chosen\\=([^& ]*)&notChosen\\=([^& ]*)(&hour\\=([^& ]*))?.*$")


## categorize the "model"
# A = random (food fight)
# B = stratified random introduced around October 24 for odd session ids
# C = crystal bowl

logs = 
  logs %>%
  mutate(session=as.integer(session)) %>% 
  mutate(session.type=if_else(
    (date>"2018-08-24"&session%%2==1),
    "B",
    "A")) 

## filter out bots and drop off everything but a session id 
## limited to no longer than a day

vdigest=Vectorize(digest::digest)
clicks = logs %>% filter(bot==FALSE) %>%
  unite("session",session,date) %>%
  mutate(session=vdigest(session)) %>%
  select(month,session,session.type,chosen,notChosen)

unweighted_scores =clicks %>% 
  filter(session.type=="A") %>% 
  gather("chosen","food",-session,-session.type,-month) %>% 
  mutate(score=if_else(chosen=="chosen",1,0)) %>% 
  group_by(food) %>% 
  summarize(raw_score=sum(score),count=n()) %>% 
  mutate(ctr=raw_score/count) 

lookup = unweighted_scores %>% select(food,ctr)

weighted = clicks %>% 
  left_join(lookup, c("chosen" = "food")) %>% 
  rename(chosen.ctr=ctr) %>% 
  left_join(lookup, c("notChosen" = "food")) %>% 
  rename(notChosen.ctr=ctr) %>%
  mutate(p=chosen.ctr/(chosen.ctr+notChosen.ctr))

weighted_scores =weighted %>% 
#  filter(session.type=="A") %>% 
  select(chosen,notChosen,p,session,session.type,month) %>%
  gather("chosen","food",-session,-session.type,-month,-p) %>% 
  mutate(score=if_else(chosen=="chosen",p,1-p)) %>% 
  group_by(food) %>% 
  summarize(raw_score=sum(score),count=n()) %>% 
  mutate(weighted_ctr=raw_score/count) 

