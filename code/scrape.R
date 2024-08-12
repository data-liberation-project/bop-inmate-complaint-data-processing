source("code/functions.R")

fac_codes <- read_csv("data/raw/facility-codes.csv")

url <- "https://www.bop.gov/mobile/locations/"

page <- read_html(url)

all_urls <- page %>%
  html_nodes("#facl_list") %>%
  html_nodes("li") %>%
  html_nodes("a") %>%
  html_attr("href")

all_urls <- all_urls[grepl("locations", all_urls)]

fac_urls_df <- as.data.frame(matrix(ncol = 2, nrow = length(all_urls)))
colnames(fac_urls_df) <- c("URL", "Code")

fac_urls_df$URL <- all_urls

fac_urls_df$Code <- all_urls %>%
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

# 78% hit rate
# close enough for now

fac_urls_df$URL <- fac_urls_df$URL %>% paste("https://www.bop.gov", ., sep = "")

fac_data <- fac_urls_df$URL %>% lapply(scrape_facility)

fac_data_df <- fac_data %>% do.call(rbind, .)

fac_df <- left_join(fac_urls_df, fac_data_df, by = c("Code" = "Fac_Code"))

# looping fix for names
i <- 0

while (((length(which(is.na(fac_df$Fac_Name))) > 0) | (length(which(str_length(fac_df$Fac_Name) == 0)) > 0)) & (i <= 5)) {
  message(i)
  incompletes <- fac_df %>% filter(is.na(Fac_Name) | (str_length(Fac_Name) == 0))
  incomps_fix <- incompletes %>%
    pull(URL) %>%
    lapply(scrape_facility) %>%
    do.call(rbind, .)
  incomps_fix <- left_join(incomps_fix, fac_urls_df, by = c("Fac_Code" = "Code")) %>% rename(Code = Fac_Code)

  fac_df <- fac_df %>%
    filter(!is.na(Fac_Name)) %>%
    filter(str_length(Fac_Name) > 0)
  fac_df <- rbind(fac_df, incomps_fix)

  i <- i + 1
}

# looping fix for addresses
i <- 0

while ((length(which(fac_df$Fac_Address == ",")) > 0) & (i <= 5)) {
  message(i)
  incompletes <- fac_df %>% filter(Fac_Address == ",")
  incomps_fix <- incompletes %>%
    pull(URL) %>%
    lapply(scrape_facility) %>%
    do.call(rbind, .)
  incomps_fix <- left_join(incomps_fix, fac_urls_df, by = c("Fac_Code" = "Code")) %>% rename(Code = Fac_Code)

  fac_df <- fac_df %>% filter(Fac_Address != ",")
  fac_df <- rbind(fac_df, incomps_fix)

  i <- i + 1
}

write.csv(fac_df, "data/processing/fac_all_data_raw.csv", row.names = FALSE)
