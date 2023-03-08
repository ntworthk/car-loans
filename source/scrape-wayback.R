#--- Script details ------------------------------------------------------------
# Creation date: 08 March 2023
# Client:        client
# Project:       car-loans
# Description:   script description
# Author:        Nick Twort

library(tidyverse)
# run:
# remotes::install_github("hrbrmstr/wayback")
library(wayback)

# See here https://hrbrmstr.github.io/wayback/articles/intro-to-mementos.html

#--- Import data ---------------------------------------------------------------

url <- "https://mozo.com.au/car-loans/articles/what-is-a-good-interest-rate-for-a-car-loan-in-australia"

mems <- get_mementos(url)

tm <- get_timemap(mems$link[2])

# Look at one page (chosen randomly)
mem <- read_memento(tm$link[11])

# Find interest rates - get 10 characters before and after all % signs
str_extract_all(mem, ".{10}%.{10}")
