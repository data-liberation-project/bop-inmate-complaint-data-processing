library(tidyverse)
library(rvest)
library(httr2)
library(RCurl)
library(tidygeocoder)
library(zipcodeR)
library(arrow)

paste_not_na <- function(vec) {
  vec <- vec[!is.na(vec)]
  return(paste(vec, collapse = ", "))
}

code_from_url <- function(url) {
  code <- url %>%
    lapply(function(x) {
      if (substr(x, str_length(x), str_length(x)) == "/") {
        return(substr(x, 1, str_length(x) - 1))
      } else {
        return(x)
      }
    }) %>%
    unlist() %>%
    str_split_i("/", -1) %>%
    str_to_upper()
  return(code)
}

url_from_code <- function(code) {
  url <- code %>%
    str_to_lower() %>%
    paste("https://www.bop.gov/locations/institutions/", ., sep = "")
  return(url)
}

scrape_facility <- function(url) {
  code <- code_from_url(url)
  sess <- read_html_live(url)
  sess$session$close()
  sess <- read_html_live(url)

  fac_details <- as.data.frame(matrix(ncol = 0, nrow = 1))

  fac_details["Fac_Code"] <- code %>% str_to_upper()

  fac_details["Fac_Name"] <- sess %>%
    html_nodes("#title_cont") %>%
    html_nodes(".facl-title") %>%
    html_text() %>%
    str_squish()

  fac_details["Fac_Description"] <- sess %>%
    html_nodes("#title_cont") %>%
    html_nodes("p") %>%
    html_text() %>%
    str_squish()

  fac_details["Fac_Address"] <- sess %>%
    html_nodes(".adr") %>%
    html_text() %>%
    str_squish()

  fac_details["Fac_Email"] <- sess %>%
    html_nodes("#email") %>%
    html_text() %>%
    str_squish()

  fac_details["Fac_Phone"] <- sess %>%
    html_nodes("#phone") %>%
    html_text() %>%
    str_squish()

  fac_details["Fac_Pop_Gender"] <- sess %>%
    html_nodes("#pop_gender") %>%
    html_text() %>%
    str_squish()

  fac_details["Fac_Pop_Count"] <- sess %>%
    html_nodes("#pop_count") %>%
    html_text() %>%
    parse_number()

  fac_details["Fac_County"] <- sess %>%
    html_nodes("#county") %>%
    html_text() %>%
    str_squish()

  fac_details["Fac_Region"] <- sess %>%
    html_nodes("#region") %>%
    html_text() %>%
    str_squish()

  sess$session$close()

  return(fac_details)
}

generate_search_url <- function(fac_name) {
  "https://www.corecivic.com/facilities?state=All&hs_name=" %>%
    paste(fac_name, sep = "") %>%
    gsub(" ", "+", .) %>%
    return()
}

priv_facility_url <- function(search_url) {
  search_url %>%
    read_html() %>%
    html_nodes(".facility") %>%
    .[1] %>%
    html_attr("href") %>%
    return()
}

priv_fac_address <- function(fac_url) {
  fac_url %>%
    read_html() %>%
    html_nodes(".address") %>%
    .[1] %>%
    html_text() %>%
    gsub("Get Directions to this Facility", "", .) %>%
    str_squish() %>%
    return()
}

priv_fac_official_name <- function(fac_url) {
  fac_url %>%
    read_html() %>%
    html_nodes('h1[itemprop="name"]') %>%
    html_text() %>%
    str_squish() %>%
    return()
}
