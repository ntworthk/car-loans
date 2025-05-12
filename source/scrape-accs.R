library(tidyverse)
library(httr)
library(rvest)
library(janitor)
library(arrow)

max_attempts <- 5
attempts <- 0

tryCatch(
  {
    while (attempts < max_attempts) {
      # Base url
      url <- "https://www2.medicareaustralia.gov.au/pdsPortal/pub/approvedCollectionCentreSearch.faces"
      
      # Initial GET request to obtain session cookies
      initial_response <- GET(url)
      
      # Extract all cookies from the response
      all_cookies <- cookies(initial_response)
      cookie_str <- paste(
        paste(all_cookies$name, all_cookies$value, sep = "="), 
        collapse = "; "
      )
      
      # Parse the page to get the form
      page_html <- content(initial_response)
      form <- html_form(page_html)[[1]]
      
      # Extract form ID from the form (should be more robust)
      form_id <- names(form$fields)[1]
      form_id <- sub(":.*$", "", form_id)  # Extract the base form ID
      
      # Get ViewState
      view_state <- form$fields$`javax.faces.ViewState`$value
      
      # Build headers with all cookies
      headers <- c(
        `Accept` = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        `Accept-Language` = "en-AU,en-NZ;q=0.9,en-GB;q=0.8,en-US;q=0.7,en;q=0.6",
        `Cache-Control` = "max-age=0",
        `Connection` = "keep-alive",
        `Content-Type` = "application/x-www-form-urlencoded",
        `Cookie` = cookie_str,
        `DNT` = "1",
        `Origin` = "https://www2.medicareaustralia.gov.au",
        `Referer` = url,
        `Sec-Fetch-Dest` = "document",
        `Sec-Fetch-Mode` = "navigate",
        `Sec-Fetch-Site` = "same-origin",
        `Sec-Fetch-User` = "?1",
        `Upgrade-Insecure-Requests` = "1",
        `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
        `sec-ch-ua` = '"Not)A;Brand";v="99", "Google Chrome";v="127", "Chromium";v="127"',
        `sec-ch-ua-mobile` = "?0",
        `sec-ch-ua-platform` = '"Windows"'
      )
      
      # Construct form data based on the actual form ID
      form_data <- list()
      form_data[[paste0(form_id, ":gui_apaNumber")]] <- ""
      form_data[[paste0(form_id, ":gui_accNumber")]] <- ""
      form_data[[paste0(form_id, ":gui_accName")]] <- ""
      form_data[[paste0(form_id, ":gui_suburb")]] <- "*"
      form_data[[paste0(form_id, ":gui_postcode")]] <- ""
      form_data[[paste0(form_id, ":gui_search")]] <- "Search"
      form_data[[paste0(form_id, "_SUBMIT")]] <- "1"
      form_data[["javax.faces.ViewState"]] <- view_state
      
      # Send POST request
      res <- POST(
        url = url,
        add_headers(.headers = headers),
        body = form_data,
        encode = "form"
      )
      
      # Try to extract tables from the response
      scraped_data <- content(res) |> 
        html_nodes("table")
      
      if (length(scraped_data) > 0) {
        scraped_data <- scraped_data |> 
          html_table(fill = TRUE) |>
          (\(x) x[[1]])() |> 
          as_tibble() |>
          clean_names() |> 
          mutate(date = Sys.Date())
        
        # Check if we have actual data (not just headers)
        if (nrow(scraped_data) > 1) {
          # Save the data
          if (file.exists("data/scraped_accs.parquet")) {
            old_data <- read_parquet("data/scraped_accs.parquet")
            full_data <- bind_rows(old_data, scraped_data)
          } else {
            full_data <- scraped_data
          }
          
          write_parquet(full_data, "data/scraped_accs.parquet")
          cat("Successfully scraped and saved data.\n")
          attempts <- max_attempts
        } else {
          cat("Found a table but it contains no data rows.\n")
          attempts <- attempts + 1
        }
      } else {
        cat("No tables found in the response.\n")
        attempts <- attempts + 1
      }
      
      # Add a delay between attempts
      if (attempts < max_attempts) {
        Sys.sleep(2)
      }
    }
  },
  error = function(e) {
    cat("Bugger, didn't work: ", conditionMessage(e), "\n")
  }
)