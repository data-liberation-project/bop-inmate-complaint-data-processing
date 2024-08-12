library(tidyverse)
source("code/functions.R")

df <- read_parquet("data/raw/complaint-filings.parquet")

facilities_df <- read_csv("data/raw/facility-codes.csv")
facility_names <- facilities_df %>% select(facility_code, facility_name)
subject_codes <- read_csv("data/raw/subject-codes.csv")

df <- df %>% rename(Case_Number = CASENBR)

# Replace level codes with human readable org levels
df <- df %>%
  mutate(
    Org_Level = gsub("F", "Facility", ITERLVL),
    Org_Level = gsub("R", "Region", Org_Level),
    Org_Level = gsub("A", "Agency", Org_Level)
  ) %>%
  select(!ITERLVL)

# Bind in facility occurred names
df <- left_join(df,
  facility_names %>% rename(Facility_Occurred_NM = facility_name),
  by = c("CDFCLEVN" = "facility_code")
) %>%
  rename(Facility_Occurred_CODE = CDFCLEVN)

# Where no name translation is available, use the code;
# otherwise use the name.
df["Facility_Occurred"] <- ifelse(is.na(df$Facility_Occurred_NM), df$Facility_Occurred_CODE, df$Facility_Occurred_NM)


# Drop the two input columns, having collapsed them
df <- df %>%
  select(!Facility_Occurred_CODE) %>%
  select(!Facility_Occurred_NM)

# Bind in facility received name
df <- left_join(df,
  facility_names %>% rename(Facility_Received_NM = facility_name),
  by = c("CDFCLRCV" = "facility_code")
) %>%
  rename(Facility_Received_CODE = CDFCLRCV)

# Where no name translation is available, use the code. Otherwise use the name
df["Facility_Received"] <- ifelse(is.na(df$Facility_Received_NM), df$Facility_Received_CODE, df$Facility_Received_NM)

# Drop the two input columns, having collapsed them
df <- df %>%
  select(!Facility_Received_CODE) %>%
  select(!Facility_Received_NM)

# Translate status code to human readable, then drop redundant binary columns
df <- df %>%
  mutate(
    Case_Status = gsub("ACC", "Accepted", CDSTATUS),
    Case_Status = gsub("REJ", "Rejected", Case_Status),
    Case_Status = gsub("CLD", "Closed Denied", Case_Status),
    Case_Status = gsub("CLG", "Closed Granted", Case_Status),
    Case_Status = gsub("CLO", "Closed Other", Case_Status),
  ) %>%
  select(!c(
    CDSTATUS,
    reject,
    deny,
    other,
    grant,
    accept
  ))

# Translate to human readable column name
df <- df %>% rename(Received_Office = CDOFCRCV)


# Join in primary and secondary descriptions and then drop redundant columns
df <- df %>%
  left_join(subject_codes %>% select(code, primary_desc, secondary_desc),
    by = c("cdsub1cb" = "code")
  ) %>%
  rename(Subject_Primary = primary_desc) %>%
  rename(Subject_Secondary = secondary_desc) %>%
  select(!CDSUB1PR) %>%
  select(!CDSUB1SC) %>%
  select(!cdsub1cb)

# Unnecessary column, value is 1 for all rows in dataset
df <- df %>% select(!submit)

# Derive from Case_Status (CDSTATUS). See docs
df <- df %>%
  select(!filed) %>%
  select(!closed)

df["Status_Reasons"] <- df[, which(colnames(df) %in% c(
  "STATRSN1",
  "STATRSN2",
  "STATRSN3",
  "STATRSN4",
  "STATRSN5"
))] %>%
  apply(1, paste_not_na)

# Remove redundant / obscure columns
df <- df %>%
  select(!c(
    comptime,
    diffreg_filed,
    diffinst,
    timely,
    untimely,
    resubmit,
    noinfres,
    attachmt,
    wronglvl,
    otherrej,
    diffreg_answer,
    overdue,
  )) %>%
  select(!c(
    STATRSN1,
    STATRSN2,
    STATRSN3,
    STATRSN4,
    STATRSN5,
  ))

# Rearrange columns for readability
df <- df %>%
  select(
    Case_Number,
    Case_Status,
    Subject_Primary,
    Subject_Secondary,
    Org_Level,
    Received_Office,
    Facility_Occurred,
    Facility_Received,
    sitdtrcv,
    sdtdue,
    sdtstat,
    Status_Reasons,
  ) %>%
  rename(
    Received_Date = sitdtrcv,
    Due_Date = sdtdue,
    Latest_Status_Date = sdtstat,
  )


# Write out into chunks to lower file size
df %>%
  filter(year(Received_Date) %in% 2000:2004) %>%
  write.csv("data/clean/filings/complaint-filings_2000-2005_clean.csv", row.names = FALSE, na = "")

df %>%
  filter(year(Received_Date) %in% 2005:2009) %>%
  write.csv("data/clean/filings/complaint-filings_2005-2009_clean.csv", row.names = FALSE, na = "")

df %>%
  filter(year(Received_Date) %in% 2010:2014) %>%
  write.csv("data/clean/filings/complaint-filings_2010-2014_clean.csv", row.names = FALSE, na = "")

df %>%
  filter(year(Received_Date) %in% 2015:2019) %>%
  write.csv("data/clean/filings/complaint-filings_2015-2019_clean.csv", row.names = FALSE, na = "")

df %>%
  filter(year(Received_Date) %in% 2020:2024) %>%
  write.csv("data/clean/filings/complaint-filings_2020-2024_clean.csv", row.names = FALSE, na = "")
