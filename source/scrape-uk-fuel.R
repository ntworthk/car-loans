#--- Script details ------------------------------------------------------------
# Creation date: 08 November 2023
# Client:        client
# Project:       junk
# Description:   script description
# Author:        Nick Twort

library(jsonlite)
library(purrr)
library(dplyr)
library(tidyr)
library(lubridate)

#--- Import data ---------------------------------------------------------------

stores <- list(
  "Applegreen UK" = "https://applegreenstores.com/fuel-prices/data.json",
  "Ascona Group" = "https://fuelprices.asconagroup.co.uk/newfuel.json",
  "Asda" = "https://storelocator.asda.com/fuel_prices_data.json",
  "bp" = "https://www.bp.com/en_gb/united-kingdom/home/fuelprices/fuel_prices_data.json",
  "Esso Tesco Alliance" = "https://www.esso.co.uk/-/media/Project/WEP/Esso/Esso-Retail-UK/roadfuelpricingscheme",
  "Morrisons" = "https://www.morrisons.com/fuel-prices/fuel.json",
  "Motor Fuel Group" = "https://fuel.motorfuelgroup.com/fuel_prices_data.json",
  "Rontec" = "https://www.rontec-servicestations.co.uk/fuel-prices/data/fuel_prices_data.json",
  "Sainsbury’s" = "https://api.sainsburys.co.uk/v1/exports/latest/fuel_prices_data.json",
  "SGN" = "https://www.sgnretail.uk/files/data/SGN_daily_fuel_prices.json",
  "Shell" = "https://www.shell.co.uk/fuel-prices-data.html"#,
  # "Tesco" = "https://www.tesco.com/fuel_prices/fuel_prices_data.json" # Tesco won't run
)

data <- map_dfr(stores, function(store) {
  
  store |> 
    fromJSON() |> 
    as_tibble() |> 
    unnest_wider(stations) |> 
    unnest_wider(location) |> 
    unnest_wider(prices) |> 
    mutate(across(c(latitude, longitude), as.numeric))
  
}, .id = "retailer")

if ("postcod" %in% colnames(data)) {
  data <- data |> 
    mutate(postcode = ifelse(is.na(postcode), postcod, postcode)) |> 
    select(-postcod)
}

data <- data |> 
  mutate(last_updated = dmy_hms(last_updated, tz = "UTC")) |> 
  pivot_longer(cols = -c(retailer, last_updated, site_id, brand, address, postcode, latitude, longitude), names_to = "fuel", values_to = "price") |> 
  mutate(scrape_date = Sys.time())

old_data <- readRDS(paste0("data/uk_fuel_prices.rds"))

bind_rows(old_data, data) |>
  saveRDS(paste0("data/uk_fuel_prices.rds"))
