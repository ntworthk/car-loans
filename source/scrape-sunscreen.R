library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)

#--- Import data ---------------------------------------------------------------

res <- GET(
  url = "https://pds.chemistwarehouse.com.au/search?identifier=AU&fh_location=//catalog01/en_AU/categories%3C{catalog01_chemau}&fh_secondid=92927"
  )

x <- content(res) |> 
  fromJSON()

data <- x$universes$universe$`items-section`$items$item[[1]]$attribute[[1]] |> 
  as_tibble() |> 
  unnest_wider(value) |> 
  select(name, value) |> 
  pivot_wider() |> 
  mutate(date = Sys.Date())


old_data <- readRDS(paste0("data/cw_sunscreen_price.rds"))

bind_rows(old_data, data) |>
  saveRDS(paste0("data/cw_sunscreen_price.rds"))

