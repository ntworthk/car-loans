library(tidyverse)
library(rvest)
library(httr)
library(jsonlite)
library(arrow)

tryCatch({
  url <- "https://mcdonalds.com.au/data/store"
  
  old_mcdonald <- read_parquet("data/mcdonalds.parquet", as_data_frame = TRUE)
  
  stores <- read_html(url) |>
    html_nodes("p") |>
    html_text() |> 
    fromJSON() |> 
    as_tibble()
  
  stores |> 
    select(-store_filter, -lat_long, -store_trading_hour) |> 
    mutate(timestamp = now()) |> 
    (\(x) bind_rows(old_mcdonald, x))() |>
    write_parquet("data/mcdonalds.parquet")
  
}, error = function(e) {
  message("Error: ", conditionMessage(e))
})

tryCatch({
  res <- GET(url = "https://www.hungryjacks.com.au/api/storelist")  
  
  old_hjs <- read_parquet("data/hungry_jacks.parquet", as_data_frame = TRUE)
  
  hjs <- map_dfr(content(res), function(x) {
    x |> 
      compact() |> 
      (\(x) {
        x$hours <- list(x$hours)
        x$location <- list(x$location)
        x$facilities <- list(x$facilities)
        x$menulog <- list(x$menulog)
        x
      })() |> 
      as_tibble_row()
  })
  
  hjs |> 
    unnest_wider(location) |> 
    select(-hours, -menulog, -facilities) |> 
    mutate(timestamp = now()) |>
    (\(x) bind_rows(old_hjs, x))() |>
    write_parquet("data/hungry_jacks.parquet")
  
}, error = function(e) {
  message("Error: ", conditionMessage(e))
})


