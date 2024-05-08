library(tidyverse)
library(httr)
library(rvest)
library(janitor)
library(arrow)

cookies <- c(
  `oam.Flash.RENDERMAP.TOKEN` = "-1gx4x5j6u",
  `TS015fa7db` = "012fa297bd9ebbfd69de3811297a4df651453775d42003aa91f7bf583eb11644963ab0c5a1340588d1708a4b12b3585d915dbadce5b3d799c894139b6d335caaf4a150ecbe",
  `BIGipServer~MCA-EBIZ-S~PO_WAS8_PRD_MCA_DIR00-30223` = "860882442.11638.0000",
  `PD-H-SESSION-ID` = "1_4_0_zU2EM9VOcfgz3gHiRu-JVB16Ga9zXsOYUH1k5tnyAfpdXd-j",
  `BIGipServerPO_ISAM_WEB_PROD_10080` = "1463090698.24615.0000",
  `dtCookie` = "v_4_srv_55_sn_8EEA3CC091331FAE489EB132C239CC42_perc_100000_ol_0_mul_1_app-3A65ac0d509da6129b_1",
  `BIGipServer~MCA-EBIZ-S~PO_WAS8_PRD_MCA_HPS00-11073` = "407897610.16683.0000",
  `TS012e88ce` = "012fa297bd0a32dd650e2a1bc2779b12ce0209d35e2003aa91f7bf583eb11644963ab0c5a100520e590680b6db2aaac4d7d9c5f2727f386675b5436b6e720fdb32de1853ecdde9629e1af449bfdf9f5420b365247cd8b7854d9ed2065d5dcdb19cf264efa4f298ac13b141bcb97515a1b9c70a5ae3ab15d16df2859fa9c1809818b13f5d63"
)

headers <- c(
  `Accept` = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
  `Accept-Language` = "en-AU,en-NZ;q=0.9,en-GB;q=0.8,en-US;q=0.7,en;q=0.6",
  `Cache-Control` = "no-cache",
  `Connection` = "keep-alive",
  `Content-Type` = "application/x-www-form-urlencoded",
  `DNT` = "1",
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

data <- "j_id652281534_2_68539874%3Agui_apaNumber=&j_id652281534_2_68539874%3Agui_accNumber=&j_id652281534_2_68539874%3Agui_accName=&j_id652281534_2_68539874%3Agui_suburb=*&j_id652281534_2_68539874%3Agui_postcode=&j_id652281534_2_68539874%3Agui_search=Search&j_id652281534_2_68539874_SUBMIT=1&javax.faces.ViewState=2P9AbfUOF0rRJCGF2viIM5TW9bybgnFTEvDh0YS413Hl1iZpvprJ%2FzoT13iP%2FpSgIy0E%2B73N04BgGXeRw5LuUkZyLxRwoMgBagqkaJtkDF%2BLU%2FmgspPe6HeeVXts%2BcHdAhwYerCTtVZvAjzR3pcO9tOxnvtG8ajyqGRguOOQwrFNkydEVk8zgR%2BsDqA%3D"

res <- POST(
  url = "https://www2.medicareaustralia.gov.au/pext/pdsPortal/pub/approvedCollectionCentreSearch.faces",
  httr::add_headers(.headers=headers),
  httr::set_cookies(.cookies = cookies),
  body = data
)

scraped_data <- res |>
  content() |> 
  html_nodes("table") |>
  html_table(fill = TRUE) |>
  (\(x) x[[1]])() |> 
  as_tibble() |>
  clean_names() |> 
  mutate(date = Sys.Date())

old_data <- read_parquet("data/scraped_accs.parquet")

full_data <- bind_rows(old_data, scraped_data)

write_parquet(full_data, "data/scraped_accs.parquet")
