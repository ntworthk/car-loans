library(httr)
library(tidyverse)
library(arrow)

res <- GET(
  url = "https://apim.hoyts.com.au/au/cinemaapi/api/movies/now-showing"
)

movies <- content(res)

movies <- movies |> 
  map_dfr(
    function(movie) {
      movie |> 
        compact() |> 
        (\(x) {
          x$attribute <- list(x$attribute)
          x$genres <- list(x$genres)
          x
        })() |> 
        as_tibble_row()
    }
  ) |> 
  mutate(timestamp = Sys.time())


concat_tables(
  read_parquet("data/hoyts_now_showing.parquet", as_data_frame = FALSE),
  arrow_table(movies)
) |> 
  write_parquet(sink = "data/hoyts_now_showing_temp.parquet")

file.rename("data/hoyts_now_showing_temp.parquet", "data/hoyts_now_showing.parquet")

res <- GET(url = "https://apim.hoyts.com.au/au/cinemaapi/api/cinemas")

cinemas <- content(res)

cinemas <- cinemas |> 
  map_dfr(function(cinema) {
    cinema |> 
      compact() |> 
      (\(x) {
        x$features <- list(x$features)
        x
      })() |> 
      as_tibble_row()
  })

concat_tables(
  read_parquet("data/hoyts_cinemas.parquet", as_data_frame = FALSE),
  arrow_table(movies)
) |> 
  write_parquet(sink = "data/hoyts_cinemas_temp.parquet")

file.rename("data/hoyts_cinemas_temp.parquet", "data/hoyts_cinemas.parquet")
