#--- Script details ------------------------------------------------------------
# Creation date: 08 March 2023
# Client:        Internal
# Project:       car-loans
# Description:   Daily scrape
# Author:        Nick Twort

library(tidyverse)
library(rvest)

#--- Import data ---------------------------------------------------------------

url <- "https://mozo.com.au/car-loans/articles/what-is-a-good-interest-rate-for-a-car-loan-in-australia"

scraped_data <- read_html(url) |> 
  html_elements(".b-wysiwyg-text p:nth-child(1)") |> 
  as.character() |> 
  str_remove_all("<b>|</b>") |> 
  str_extract_all("average [a-z]+ car loan rate is .{1,4}%") |> 
  first() |> 
  enframe(name = NULL) |> 
  mutate(
    type = str_extract(value, "new|used"),
    rate = parse_number(value),
    date = Sys.Date()
    ) |> 
  select(date, type, rate)

write_csv(scraped_data, file.path("data", paste0("scraped_rates_", Sys.Date(), ".csv")))
