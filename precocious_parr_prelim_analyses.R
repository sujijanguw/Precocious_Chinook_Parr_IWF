#==============================================================================#
#   PRELIMINARY ANALYSES FOR CHINOOK SALMON PRECOCIOUS PARR FROM THE           #
#   IDAHO WILD FISH DATASET                                                    #
#==============================================================================#
#______________________________________________________________________________#
#                                                                              #

# Copyright 2026 U.S. Federal Government (in countries where
# recognized)

# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific language governing
# permissions and limitations under the License.

# This script provides preliminary analyses of dynamics of Chinook salmon
# precocious parr across 16 streams in the Salmon River headwaters





#===============================================================================
#   ACQUISITIONS
#===============================================================================

# Libraries
    library(plotrix)
    library(sf)
    library(viridis)
    library(lubridate)
    library(dplyr)

# Acquires metadata about the sites and the sample area
    sites <- read.csv("meta/sites.csv", row.names = 1)
    sam_area <- read.csv("meta/sample_area_m2.csv", row.names = 1)
   
# Acquires the sample metadata 
  meta_raw <- read.csv("assembled/idaho_wild_fish_metadata_2026_02_06.csv")
  
# Acquires the assembled data
  data_raw <- read.csv("assembled/idaho_wild_fish_tag_data_2026_02_06.csv")
   
# Acquires the salmon river flowline shapefile
    salmon <- st_read(dsn = "spatial", layer = "Salmon_streams")

    


    
#===============================================================================
#   DATA SHAPING
#===============================================================================
    
# Merges the sample metadata with the raw data
    data_merge <- left_join(meta_raw[, c(24, 5, 7, 12)], data_raw)

# Converts the event date to an actual date
    data_merge$event_date <- parse_date_time(data_merge$event_date,
        order = c("YmdHMS", "mdYHM"))
    
# Adds a year metric
    data_merge$year <- year(data_merge$event_date)
    
# Extracts Chinook (spring/summer wild)
    data_merge <- data_merge[data_merge$srr_code %in% c("11W", "12W"), ]
    
# Extracts precocious parr
    prec_merge <- data_merge[grep("PR", data_merge$conditional_comments), ]

# Extracts regular parr
    reg_merge <- data_merge[-grep("PR", data_merge$conditional_comments), ]
    

# Removes years before 2001. This was the first year where observers were
# regularly recording precocious parr at multiple sites (n = 4 total fish
# before this year)
    prec_merge <- prec_merge[prec_merge$year > 2000, ]
    
# Tallies par by site by year
    pp_y_s <- tapply(prec_merge$year, list(prec_merge$year,
      prec_merge$event_site), length)
    pp_y_s <- ifelse(is.na(pp_y_s), 0, pp_y_s)

# Calculates parr density
    pp_den <- pp_y_s / (sam_area/10000)    
    
    

    

    
#______________________________________________________________________________#
#                                                                              #
#==============================================================================#
#   END OF SCRIPT                                                              #
#==============================================================================#
