source("code/functions.R")
library(rvest)

# not yet reliable
# not to be committed into main data

fac_codes <- read_csv("data/raw/facility-codes.csv")

fac_df <- read_csv("data/clean/facilities/facility-locations.csv")

df <- fac_df %>%
  filter(is.na(Facility_Address)) %>%
  select(Facility_Code, Facility_Name)

df["Name_Clean"] <- df %>%
  pull(Facility_Name) %>%
  gsub(" CCM", "", .) %>%
  gsub(" FCI", "", .) %>%
  gsub(" CI", "", .) %>%
  gsub(" FL", "", .) %>%
  gsub(" FPC", "", .) %>%
  gsub(" CORR CTR", "", .) %>%
  gsub(" CORR FCL", "", .) %>%
  str_squish()

df["Search_URL"] <- df$Name_Clean %>%
  generate_search_url()

df["Fac_URL"] <- df$Search_URL %>%
  lapply(priv_facility_url) %>%
  lapply(function(x) {
    if (length(x) == 0) {
      return(NA)
    } else {
      return(x)
    }
  }) %>%
  unlist()

df <- df %>%
  filter(!is.na(Fac_URL))

df$Fac_URL <- df %>%
  pull(Fac_URL) %>%
  paste("https://www.corecivic.com", ., sep = "")

df["Facility_Address"] <- df %>%
  pull(Fac_URL) %>%
  lapply(priv_fac_address) %>%
  unlist()

df["Official_Name"] <- df %>%
  pull(Fac_URL) %>%
  lapply(priv_fac_official_name) %>%
  unlist()
