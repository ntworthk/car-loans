library(tidyverse)
library(httr)
library(rvest)
library(arrow)

headers = c(
  accept = "application/json, text/plain, */*",
  `accept-language` = "en,en-AU;q=0.9,en-NZ;q=0.8,en-GB;q=0.7,en-US;q=0.6",
  `cache-control` = "no-cache",
  dnt = "1",
  pragma = "no-cache",
  priority = "u=1, i",
  referer = "https://up.com.au/home-loans/fees-and-rates/",
  `sec-ch-ua` = '"Not)A;Brand";v="99", "Google Chrome";v="127", "Chromium";v="127"',
  `sec-ch-ua-mobile` = "?0",
  `sec-ch-ua-platform` = '"Windows"',
  `sec-fetch-dest` = "empty",
  `sec-fetch-mode` = "cors",
  `sec-fetch-site` = "same-origin",
  `user-agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"
)

res <- httr::GET(url = "https://up.com.au/home_loans_data", httr::add_headers(.headers=headers))

x <- content(res)

up_home_loans <- x$current_interest_rates |> 
  enframe() |> 
  unnest(value) |> 
  pivot_wider(id_cols = everything()) |> 
  mutate(
    across(matches("rate"), as.numeric),
    announce_at = with_tz(ymd_hms(announce_at), "Australia/Sydney"),
    start_date = ymd(start_date)
  ) |> 
  mutate(timestamp = Sys.time())


concat_tables(
  read_parquet("data/up_home_loans.parquet", as_data_frame = FALSE),
  arrow_table(up_home_loans)
) |> 
  write_parquet(sink = "data/up_home_loans_temp.parquet")

file.rename("data/up_home_loans_temp.parquet", "data/up_home_loans.parquet")



