#--- Script details ------------------------------------------------------------
# Creation date: 08 March 2023
# Client:        Internal
# Project:       car-loans
# Description:   Daily scrape
# Author:        Nick Twort

library(tidyverse)
library(rvest)

#--- Import data ---------------------------------------------------------------

url <- "https://www.ozbargain.com.au/"

now <- Sys.time()

scraped_data <- read_html(url) |> 
  html_element(".node-teaser")

ob_page <- scraped_data |> 
  html_elements("a") |> 
  (\(x) x[str_detect(html_attr(x, "href"), "node")])() |> 
  html_attr("href") |> 
  (\(x) paste0("https://www.ozbargain.com.au", x))()

ob_title <- scraped_data |> 
  html_elements("a") |> 
  (\(x) x[str_detect(html_attr(x, "href"), "node")])() |> 
  html_text()

ob_link <- scraped_data |> 
  html_element("a") |> 
  html_attr("title") |> 
  str_remove("Go to ")

ob_site <- ob_link |> 
  str_extract("https://[^/]+")

ob_user <- scraped_data |> 
  html_elements("a") |> 
  (\(x) x[str_detect(html_attr(x, "href"), "user")])() |> 
  html_text()

ob_user_id <- scraped_data |> 
  html_elements("a") |> 
  (\(x) x[str_detect(html_attr(x, "href"), "user")])() |> 
  html_attr("href") |> 
  str_remove("/user/") |> 
  as.integer()

ob_cat <- scraped_data |> 
  html_elements("a") |> 
  (\(x) x[str_detect(html_attr(x, "href"), "cat")])() |> 
  html_attr("href") |> 
  str_remove("/cat/")

ob_text <- scraped_data |> 
  html_elements("p") |> 
  html_text()

todays <- tibble(
  datetime = now,
  page = ob_page,
  title = ob_title,
  link = ob_link,
  site = ob_site,
  user = ob_user,
  user_id = ob_user_id,
  cat = ob_cat,
  text = ob_text
)

previous <- read_csv(file.path("data", paste0("scraped_ob.csv")), col_types = "Tcccccicc")

write_csv(bind_rows(previous, todays), file.path("data", paste0("scraped_ob.csv")))
