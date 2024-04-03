#--- Script details ------------------------------------------------------------
# Creation date: 3 April 2024
# Client:        Internal
# Project:       car-loans
# Description:   Daily scrape
# Author:        Nick Twort

library(tidyverse)
library(rvest)

#--- Import data ---------------------------------------------------------------

url <- "https://news.ycombinator.com/news"

scraped_data <- read_html(url) |> 
  html_nodes("table") |>
  html_table(fill = TRUE) |>
  magrittr::extract2(3) |>
  as_tibble() |>
  janitor::clean_names() |> 
  (\(x) {colnames(x) <- c("rank", "skip", "desc"); x})() |>
  select(-skip) |> 
  fill(rank, .direction = "down") |> 
  filter(desc != "More") |> 
  group_by(rank) |> 
  mutate(helper = row_number()) |> 
  ungroup() |> 
  pivot_wider(names_from = helper, values_from = desc) |> 
  (\(x) {colnames(x) <- c("rank", "desc", "details"); x})() |> 
  mutate(pts = parse_number(str_extract(details, "[0-9]+ point"))) |> 
  mutate(author = str_remove(str_extract(details, "by [^\\s]+"), "by ")) |> 
  mutate(time = str_extract(details, "[0-9]+ [A-z]+ ago")) |> 
  mutate(comments = parse_number(str_extract(details, "[0-9]+\\scomments")))

scraped_data <- scraped_data |> 
  mutate(date = Sys.Date())

old_data <- read_rds("data/scraped_hn.rds")

full_data <- bind_rows(old_data, scraped_data)

write_rds(full_data, "data/scraped_hn.rds")

