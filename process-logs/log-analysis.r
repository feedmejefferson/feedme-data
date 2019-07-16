library(tidyverse)

logs = fs::dir_ls("raw",recurse = TRUE, regexp = "\\.json$") %>%
  map_dfr(ndjson::stream_in) %>%
  filter(severity=="INFO") %>%
  select(insertId, timestamp, textPayload) %>%
  mutate(month=lubridate::month(timestamp),week=lubridate::week(timestamp))


## there has to be a better way to do this inline. scan gives
## us quoted parsing with a delimiter out of the box, but this
## is definitely a bit hacky
textPayload = scan(text=logs$textPayload, what=list(ip.address="", user.agent="", json=""))
logs$ip.address = textPayload$ip.address
logs$user.agent = textPayload$user.agent
logs$json = textPayload$json
## we need to coerce the modified df back into a homogenous type
## for the unnest to work
logs = as_tibble(logs)
logs$json = map(logs$json, fromJSON)
logs = select(logs, -c(textPayload))
clicks = unnest(logs, json)
