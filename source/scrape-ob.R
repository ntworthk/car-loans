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

dat <- bind_rows(previous, todays)


g <- dat |> 
  group_by(date(datetime)) |> 
  filter(row_number() == n()) |> 
  ungroup() |> 
  count(cat, sort = TRUE) |> 
  mutate(cat = fct_inorder(cat, ordered = TRUE)) |> 
  ggplot(aes(x = n, y = cat)) + 
  geom_col(fill = "#75A99C") +
  geom_vline(xintercept = 0) +
  scale_x_continuous(expand = expansion(c(0, 0.05))) +
  theme_light(base_family = "Lato", base_size = 12) +
  theme(
    panel.grid.major.y= element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.background = element_blank(),
    plot.background = element_blank(),
    legend.background = element_blank(),
    legend.position = "bottom",
    strip.background = element_rect(fill = "#E6E7E8")
  )

ggsave(filename = "figures/png/ob_cats.png",
       plot = g,
       width = 17.00,
       height = 11.46,
       units = "cm"
)

