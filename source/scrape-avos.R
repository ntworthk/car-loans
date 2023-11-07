library(tidyverse)
library(httr)

headers = c(
  `authority` = "www.woolworths.com.au",
  `accept` = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
  `accept-language` = "en-AU,en-NZ;q=0.9,en-GB;q=0.8,en-US;q=0.7,en;q=0.6",
  `cache-control` = "max-age=0",
  `dnt` = "1",
  `sec-ch-ua` = '"Google Chrome";v="111", "Not(A:Brand";v="8", "Chromium";v="111"',
  `sec-ch-ua-mobile` = "?0",
  `sec-ch-ua-platform` = '"Windows"',
  `sec-fetch-dest` = "document",
  `sec-fetch-mode` = "navigate",
  `sec-fetch-site` = "none",
  `sec-fetch-user` = "?1",
  `upgrade-insecure-requests` = "1",
  `user-agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
)

res <- httr::GET(url = "https://www.woolworths.com.au/", httr::add_headers(.headers=headers))

cookies <- cookies(res)
tmp_cookies <- cookies$value
names(tmp_cookies) <- cookies$name
cookies <- tmp_cookies
cookies["bff_region"] <- "syd2"


res <- httr::GET(url = "https://www.woolworths.com.au/apis/ui/product/detail/186910", httr::add_headers(.headers=headers), set_cookies(cookies))

avos <- content(res)

today_avo <- tibble(date = Sys.Date(), price = avos$Product$Price)

old_avos <- read_rds("data/avos.rds")

all_avos <- bind_rows(old_avos, today_avo)

write_rds(all_avos, "data/avos.rds")


g <- all_avos |> 
  ggplot(aes(x = date, y = price)) +
  geom_line()

ggsave(filename = "figures/png/avo_price.png",
       plot = g,
       width = 17.00,
       height = 11.46,
       units = "cm"
)
