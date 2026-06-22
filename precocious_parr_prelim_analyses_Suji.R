# Loading the required packages
library(dplyr)
library(sf)

#loading the data into R's memory
parr_data <- read.csv("assembled/precocious_parr_m2.csv")
temp_data <- read.csv("explanatory/sample_modeled_temp_C.csv")
landcover_data <- read.csv("explanatory/sample_lulc_proportions.csv")
catchment_data <- read.csv("explanatory/site_watershed_architecture.csv")

#joining everything into one dataset
master_parr_data <- parr_data %>%
    # glue the temp data matching by site and year
    left_join(temp_data, by = c("Ptagis_ID", "Year")) %>%
    # glue the landcover data
    left_join(landcover_data, by = c("Ptagis_ID", "Year")) %>%
    # glue the catchment shape data 
    left_join(catchment_data, by = "Ptagis_ID")

head(master_parr_data)
