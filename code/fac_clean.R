source("code/functions.R")

fac_codes <- read_csv("data/raw/facility-codes.csv")
fac_data <- read_csv("data/processing/fac_all_data_raw.csv")
arch_fac_data <- read_csv("data/raw/bop-facility-codes-scraped.csv")

# BOP official facility coordinates obtained from header of HTML page
# at https://www.bop.gov/locations/map.jsp
#
# Raw results stored in in data/raw/locations_raw.txt and then
# converted from JSON-like text to CSV using https://konklone.io/json/
#
# Loaded as CSV and cleaned here.

# Clean up BOP's version of the location data
fac_locations <- read_csv("data/processing/fac_locations_official/locations_converted.csv")
colnames(fac_locations) <- colnames(fac_locations) %>% gsub("0/", "", .)
fac_locations <- fac_locations %>%
  select(code, latitude, longitude)

# Bring in initial fac data
fac_df <- left_join(fac_codes, fac_data, by = c("facility_code" = "Code"))

fac_df <- fac_df %>%
  select(
    facility_code,
    facility_name,
    Fac_Address
  )

fac_df <- left_join(fac_df, fac_locations, by = c("facility_code" = "code"))

# This only gets a 60% coverage rate
official_locations_df <- fac_df %>%
  filter(!is.na(latitude)) %>%
  rename(lat = latitude) %>%
  rename(long = longitude)
official_locations_df["Fac_Coords_Method"] <- "BOP Official"

fac_df <- fac_df %>%
  filter(is.na(latitude)) %>%
  select(
    facility_code,
    facility_name,
    Fac_Address
  )

# Geocoding
census_coded <- fac_df %>%
  geocode(address = Fac_Address, method = "census", verbose = TRUE)
census_coded["Fac_Coords_Method"] <- "U.S. Census"

census_missing <- census_coded %>%
  filter(is.na(lat)) %>%
  pull(facility_code)

census_coded <- rbind(
  official_locations_df,
  census_coded %>%
    filter(!(facility_code %in% official_locations_df$facility_code))
)

fac_df <- census_coded %>%
  filter(!is.na(lat))

# Additional address cleaning
fac_df["zipcode"] <- fac_df %>%
  pull(Fac_Address) %>%
  str_split_i(" ", -1)

fac_df <- fac_df %>%
  pull(zipcode) %>%
  lapply(reverse_zipcode) %>%
  do.call(rbind, .) %>%
  select(zipcode, major_city, state) %>%
  unique() %>%
  left_join(fac_df, ., by = "zipcode") %>%
  select(!zipcode) %>%
  rename(city = major_city)

fac_df <- left_join(fac_codes, fac_df, by = c("facility_code", "facility_name"))

fac_df <- fac_df %>%
  select(
    facility_code,
    facility_name,
    Fac_Address,
    lat,
    long,
    city,
    state,
    Fac_Coords_Method
  )

colnames(fac_df) <- str_to_title(colnames(fac_df))
fac_df <- fac_df %>%
  rename(Facility_Name = Facility_name) %>%
  rename(Facility_Address = Fac_address) %>%
  rename(Fac_Coords_Method = Fac_coords_method) %>%
  rename(Facility_Code = Facility_code)

write.csv(fac_df, "data/clean/facilities/facility-locations.csv", row.names = FALSE)
