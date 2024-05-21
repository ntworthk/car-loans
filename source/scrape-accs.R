library(tidyverse)
library(httr)
library(rvest)
library(janitor)
library(arrow)

max_attempts <- 5
attempts <- 0

while (attempts < max_attempts) {
  
  
  
  # Base url
  url <- "https://www2.medicareaustralia.gov.au/pext/pdsPortal/pub/approvedCollectionCentreSearch.faces"
  
  # Start a session to get parameters
  s <- session(url)
  
  # Get the id
  face_id <- s |> 
    html_form() |> 
    (\(x) x[[1]])() |> 
    magrittr::extract2("fields") |> 
    magrittr::extract2("javax.faces.ViewState") |>
    magrittr::extract2("value")
  
  # Extract and format cookies
  cooks <- cookies(s) |> 
    as_tibble()
  cookies <- cooks$value
  names(cookies) <- cooks$name
  
  headers <- c(
    `Accept` = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    `Accept-Language` = "en-AU,en-NZ;q=0.9,en-GB;q=0.8,en-US;q=0.7,en;q=0.6",
    `Cache-Control` = "no-cache",
    `Connection` = "keep-alive",
    `Content-Type` = "application/x-www-form-urlencoded",
    `DNT` = "1",
    `Host` = "www2.medicareaustralia.gov.au",
    `Origin` = "https://www2.medicareaustralia.gov.au",
    `Pragma` = "no-cache",
    `Referer` = "https://www2.medicareaustralia.gov.au/pext/pdsPortal/pub/approvedCollectionCentreSearch.faces",
    `Sec-Fetch-Dest` = "document",
    `Sec-Fetch-Mode` = "navigate",
    `Sec-Fetch-Site` = "same-origin",
    `Sec-Fetch-User` = "?1",
    `Upgrade-Insecure-Requests` = "1",
    `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    `sec-ch-ua` = '"Chromium";v="124", "Google Chrome";v="124", "Not-A.Brand";v="99"',
    `sec-ch-ua-mobile` = "?0",
    `sec-ch-ua-platform` = '"Windows"'
  )
  
  # Let's go
  data <- paste0(
    "j_id652281534_2_68539874%3Agui_apaNumber=&j_id652281534_2_68539874%3Agui_accNumber=&j_id652281534_2_68539874%3Agui_accName=&j_id652281534_2_68539874%3Agui_suburb=*&j_id652281534_2_68539874%3Agui_postcode=&j_id652281534_2_68539874%3Agui_search=Search&j_id652281534_2_68539874_SUBMIT=1&javax.faces.ViewState=",
    URLencode(face_id, TRUE)
  )
  
  # leggo
  res <- POST(
    url = url,
    add_headers(.headers=headers),
    set_cookies(.cookies = cookies),
    body = data
  )
  
  scraped_data <- res |>
    content() |> 
    html_nodes("table")
  
  if (length(scraped_data) > 0) {
    scraped_data <- scraped_data |> 
      html_table(fill = TRUE) |>
      (\(x) x[[1]])() |> 
      as_tibble() |>
      clean_names() |> 
      mutate(date = Sys.Date())
    
    
    old_data <- read_parquet("data/scraped_accs.parquet")
    
    full_data <- bind_rows(old_data, scraped_data)
    
    write_parquet(full_data, "data/scraped_accs.parquet")
    
    attempts <- max_attempts
    
  } else {
    attempts <- attempts + 1
  }
  
}
