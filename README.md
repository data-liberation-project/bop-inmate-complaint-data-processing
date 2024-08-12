# BOP Inmate Complaint Data Processing

## Overview

This repository contains raw data, processing code, and the outputs of a volunteer-driven effort to provide a more human-readable version of the [federal inmate complaint dataset](https://docs.google.com/document/d/1vTuyUFNqS9tex4_s4PgmhF8RTvTb-uFMN5ElDjjVHTM/edit) the Bureau of Prisons (BOP) has provided to the [Data Liberation Project](https://www.data-liberation-project.org/) (DLP).

This effort has been led by [Declan Bradley](https://github.com/declanrjb), with contributions from [Jeremy Singer-Vine](https://github.com/jsvine).

## Data Sources

The raw [complaint-filings dataset](data/raw/complaint-filings.parquet), [facility code translations](data/raw/facility-codes.csv), and [complaint-subject code translations](data/raw/subject-codes.csv) come from the Data Liberation Project's [data release of BOP records received via FOIA](https://docs.google.com/document/d/1vTuyUFNqS9tex4_s4PgmhF8RTvTb-uFMN5ElDjjVHTM/edit).

[Additional facility code translations](data/raw/bop-facility-codes-scraped.csv) were scraped from a [BOP web page](https://www.bop.gov/locations/list.jsp) via the [Wayback Machine](http://wayback.archive.org/). 

Official [facility location data](data/raw/locations_raw.txt) were obtained from BOP's [facility map](https://www.bop.gov/locations/map.jsp). Additional location information was gathered through the [US Census Bureau's geocoder](https://geocoding.geo.census.gov/geocoder/).

## Data Processing

The goal of the output ("clean") datasets is to provide versions of the inmate filing data that:

- Provide more human-readable translations for the shortened codes used in the raw data to represent facilities and subject matter
- Provide more explicit column names
- Provide the data in smaller-sized files
- Remove redundant columns (i.e., those derived deterministically from other available columns)
- Provide additional metadata relating to each filing's relevant facilities

## Output

### Filings

The [`data/clean/filings/`](data/clean/filings/) subdirectory contains the main output of this data pipeline. It contains one file for each of the following time periods, based on each filing's submission date:

- 2000-2005
- 2005-2009
- 2010-2014
- 2015-2019
- 2020-2024

Each file is between 48 and 80 megabytes, and between roughly 300,000 and 430,000 rows. They contain the following columns:

| Column Name | Description | Sample Row |
|-------------|-------------|------------|
| `Case_Number` | Remedy Case Number; see main documentation for caveats re. repeated case numbers. | `1132042` |
| `Case_Status` | Case status for this particular filing. | `Rejected` |
| `Subject_Primary` | Broad category of complaint. | `MEDICAL-EXC. FORCED TREATMENT` |
| `Subject_Secondary` | Narrower category of complaint. | `OTHER MEDICAL MATTERS` |
| `Org_Level` | Level at which the filing was submitted. (Facility, Region, or Agency; see main documentation for details.) | `Agency` |
| `Received_Office` | Office that received the filing. | `BOP` |
| `Facility_Occurred` | Facility where the event(s) in question occurred. These files replace the three-letter facility code with a fuller name, where available. Where those fuller names are not available, this column retains the three-letter code. | `FORT DIX FCI` |
| `Facility_Received` | Facility where the inmate resided when the filing was submitted. See note above re. code translations. | `SANDSTONE FCI` |
| `Received_Date` | Date the filing was received by BOP. | `2022-10-25` |
| `Due_Date` | The regulations-required deadline for the BOP's response. Not applicable for rejected filings. | |
| `Latest_Status_Date` | The date of the most recent status change. | `2022-11-17` |
| `Status_Reasons` | The reasons provided for BOP's determination. See the main documentation for a translation of these values, which are too lengthy to include directly in these files. | `WRL, DIR, OTH` |

### Facilities

The [`data/clean/facilities/facility-locations.csv`](data/clean/facilities/facility-locations.csv) file contains location information relating to each facility (attaining ~97% coverage), and can be joined back to the filings data's `Facility_Occurred` and `Facility_Received` columns. It contains the following columns:

| Column Name | Description | Sample Row |
|-------------|-------------|------------|
| `Facility_Code` | The facility's official three-letter code. | `CAT` |
| `Facility_Name` | The facility's longer name. | `ATLANTA CCM` |
| `Facility_Address` | The facility's address, per BOP's website. | `719 MCDONOUGH BLVD S.E. ATLANTA, GA 30315` |
| `Lat` | The latitude of that address. | `33.7118817336429` |
| `Long` | The longitiude of that address. | `-84.3639063835144` |
| `City` | The facility's city. | `Atlanta` |
| `State` | The facility's state. | `GA` |
| `Fac_Coords_Method` | The source of the geocoordinates; either `BOP Official` or `U.S. Census` (i.e., from the Census Bureau's Geocoder). | `BOP Official` |

## Code

The `code` directory contains the following scripts:

- `scrape.R`: Scrapes facility information from [BOP's website](https://www.bop.gov/mobile/locations/). 
- `fac_clean.R`: Creates [`data/clean/facilities/facility-locations.csv`](data/clean/facilities/facility-locations.csv), based on data provided by BOP via FOIA and online, as well as ZIP code metadata and geocoding results.
- `merge.R`: Reads the raw complaints data, merges it with the facility data, expands status and subject codes, and removes redundant columns, writing the results to output files in [`data/clean`](data/clean).
- `private_facs.R`: A work in progress to obtain information about privately-run facilities; not yet used in the results.
- `functions.R`: Contains various helper functions used in the scripts above.

## Reproducibility

The code in this repository requires `R` to be installed on your computer. Its package dependencies are managed via [`renv`](https://rstudio.github.io/renv/). To install them, run `make dependencies`.

To run the main data cleaning and merging steps, run `make data` or:

```sh
Rscript code/fac_clean.R
Rscript code/merge.R
```

## Licensing

The files in [`data/raw`](data/raw) can be considered public domain and are provided without restriction. All other data files have been generated by the Data Liberation Project and are available under Creative Commons’ [CC BY-SA 4.0 license terms](https://creativecommons.org/licenses/by-sa/4.0/). This repository’s code is available under the [MIT License terms](https://opensource.org/license/mit/).
