library(httr)
library(tidyverse)

headers = c(
  `authority` = "www.wilsonparking.com.au",
  `accept` = "*/*",
  `accept-language` = "en-AU,en-NZ;q=0.9,en-GB;q=0.8,en-US;q=0.7,en;q=0.6",
  `content-type` = "application/json",
  `dnt` = "1",
  `referer` = "https://www.wilsonparking.com.au/book-online/?carParkFeature=12",
  `sec-ch-ua` = '"Google Chrome";v="111", "Not(A:Brand";v="8", "Chromium";v="111"',
  `sec-ch-ua-mobile` = "?0",
  `sec-ch-ua-platform` = '"Windows"',
  `sec-fetch-dest` = "empty",
  `sec-fetch-mode` = "cors",
  `sec-fetch-site` = "same-origin",
  `user-agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
)

params = list(
  `latitude` = "-33.8688197",
  `longitude` = "151.2092955",
  `sort` = "undefined",
  `distance` = "5000000"
)

res <- GET(
  url = "https://www.wilsonparking.com.au/api/v2/GetParkingByLocation",
  add_headers(.headers=headers),
  query = params
  )

parks <- content(res)$carParks

write_rds(parks, file.path("data", paste0("scraped_parks_", Sys.Date(), ".rds")))

old_mp_data <- read_rds(file.path("data", "scraped_parks_mp.rds"))
new_mp_data <- map_dfr(parks, function(park) {
  
  if (park$carParkNumber != 2078) {
    return(tibble())
  }
  
  map_dfr(park$rates, function(y) {
    
    map_dfr(y$rates, as_tibble_row) |> 
      mutate(rateType = y$rateType)
    
  }) |> 
    mutate(name = park$name, number = park$carParkNumber)
  
})  |> 
  filter(rateType == "Hourly", timeSpan == "0.0 - 1.0 hrs") |> 
  mutate(date = file.path("data", paste0("scraped_parks_", Sys.Date(), ".rds")))

all_mp_data <- bind_rows(old_mp_data, new_mp_data)
write_rds(all_mp_data, file.path("data", "scraped_parks_mp.rds"))

g <- all_mp_data |> 
  mutate(date = parse_date(str_remove_all(date, "data.*_|\\.rds"))) |> 
  ggplot(aes(x = date, y = price)) +
  geom_line() +
  geom_point() +
  labs(title = "Price at 25 Martin Place car park for < 1 hour")

ggsave(filename = "figures/png/car_price.png",
       plot = g,
       width = 17.00,
       height = 11.46,
       units = "cm"
)

