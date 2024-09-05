library(tidyverse)
library(httr)
library(rvest)
library(arrow)

headers = c(
  Accept = "application/json, text/javascript, */*; q=0.01",
  `Accept-Language` = "en-AU,en-NZ;q=0.9,en-GB;q=0.8,en-US;q=0.7,en;q=0.6",
  `Cache-Control` = "no-cache",
  Connection = "keep-alive",
  `Content-Type` = "application/x-www-form-urlencoded; charset=UTF-8",
  DNT = "1",
  Origin = "https://www.lifeblood.com.au",
  Pragma = "no-cache",
  Referer = "https://www.lifeblood.com.au/blood/blood-supply-levels",
  `Sec-Fetch-Dest` = "empty",
  `Sec-Fetch-Mode` = "cors",
  `Sec-Fetch-Site` = "same-origin",
  `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
  `X-Requested-With` = "XMLHttpRequest",
  `sec-ch-ua` = '"Not)A;Brand";v="99", "Google Chrome";v="127", "Chromium";v="127"',
  `sec-ch-ua-mobile` = "?0",
  `sec-ch-ua-platform` = '"Windows"'
)

params = list(
  ajax_form = "1",
  `_wrapper_format` = "drupal_ajax"
)

states <- c("all australia", "australian capital territory", "tasmania", "new south wales", "northern territory", "queensland", "south australia", "victoria", "western australia")
names(states) <- states

blood_levels <- map_dfr(
  states,
  function(state) {
    
    data = list(
      form_build_id = "form-nvZEPBid8saHd3pqCo8mkGUCoit2loa0DpMaqfe4mnk",
      form_id = "stock_level_form",
      lb_region_select = "victoria",
      `_triggering_element_name` = "lb_region_select",
      `_drupal_ajax` = "1",
      `ajax_page_state[theme]` = "arcbs",
      `ajax_page_state[theme_token]` = "",
      `ajax_page_state[libraries]` = "eJyNUUFywyAM_BCGJzEyyLYSGVEETtzXl9ietIccegHtame1CChhVBcYVHebJKKBg5lZRuBB686U5ovk0WuVcD-hnzFhAXYRKjDsWAbcMFU1I9aKxeMzi2L0E3GH3fPUm3DHSFWKhxCkRJLk3pWdiqSKKZrA9DKjiH4Dpj6kt_3tq2HZXdjsWVma8L_Sq4dmgoBVXSwtA9sT2f7O-_CgOGP9LNgIHzrADZ5mIuTo5yItO2Rc-3S7SKHvnh3YVxjV9I1Iqz6SBtleQSRhEDYZCswF8vL2_2VsS7mNTLpgNEprZvRZcst-5L53dR84o7tWXN0IiubI6I7THkn_EqvExpfGv7p-of6fPdp1_wCnTc8B"
    )
    
    res <- httr::POST(
      url = "https://www.lifeblood.com.au/blood/blood-supply-levels",
      httr::add_headers(.headers=headers),
      query = params,
      # httr::set_cookies(.cookies = cookies),
      body = data,
      encode = "form"
      )
    
    res |> 
      content() |> 
      (\(x) x[[3]]$data)() |> 
      read_html() |> 
      html_elements(".drop") |> 
      html_attr(name = "aria-label") |> 
      enframe(name = NULL) |> 
      mutate(value = str_remove_all(value, "blood type ")) |> 
      separate_wider_regex(
        value,
        patterns = c(
          type = "[A-z]+",
          " ",
          direction = "positive|negative",
          " level is ",
          status = "[A-z]+",
          "\\."
        )
      )
    
  },
  .id = "state"
) |> 
  mutate(timestamp = Sys.time())

concat_tables(
  read_parquet("data/blood_levels.parquet", as_data_frame = FALSE),
  arrow_table(blood_levels)
) |> 
  write_parquet(sink = "data/blood_levels_temp.parquet")

file.rename("data/blood_levels_temp.parquet", "data/blood_levels.parquet")

