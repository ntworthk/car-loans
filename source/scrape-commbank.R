#--- Script details ------------------------------------------------------------
# Creation date: 08 March 2023
# Client:        Internal
# Project:       car-loans
# Description:   Daily scrape
# Author:        Nick Twort

library(tidyverse)
library(rvest)

#--- Import data ---------------------------------------------------------------

url <- "https://www.commbank.com.au/personal/accounts/comparison-table.html"

scraped_data <- read_html(url) |> 
  html_nodes("table") |>
  html_table(fill = TRUE) |>
  magrittr::extract2(2) |>
  as_tibble() |>
  janitor::clean_names() |> 
  (\(x) {colnames(x) <- unlist(x[1 ,]); x})() |> 
  filter(if_any(everything(), str_detect, "%")) |> 
  first() |> 
  pivot_longer(everything()) |> 
  mutate(perc = str_extract_all(value, "[0-9].[0-9]{2}%")) |> 
  rowwise() |> 
  filter(length(perc) > 0) |> 
  mutate(p1 = max(perc)) |> 
  filter(name == "NetBank Saver Account") |> 
  pull(p1) |> 
  parse_number() |> 
  magrittr::multiply_by(1/100)

scraped_data <- tibble(date = Sys.Date(), netbank_saver_rate = scraped_data)

old_data <- read_rds("data/scraped_commbank_rates.rds")

full_data <- bind_rows(old_data, scraped_data)

write_rds(full_data, "data/scraped_commbank_rates.rds")

g <- full_data |> 
  ggplot(aes(x = date, y = netbank_saver_rate)) +
  geom_line() +
  geom_point() +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.01))

ggsave(filename = "figures/png/commbank_rate.png",
       plot = g,
       width = 17.00,
       height = 11.46,
       units = "cm"
)
