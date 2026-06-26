#(voided this because already produced the file)
# # Loading the required packages
# library(dplyr)
# library(sf)
# 
# #loading the data into R's memory
# parr_data <- read.csv(here("assembled", "idaho_wild_fish_metadata_2026_02_06.csv"))
# temp_data <- read.csv(here("explanatory", "sample_modeled_temp_C.csv"))
# landcover_data <- read.csv(here("explanatory", "sample_lulc_proportions.csv"))
# catchment_data <- read.csv(here("explanatory", "site_watershed_architecture.csv"))
# 
# #joining everything into one dataset
# master_parr_data <- parr_data %>%
#   # glue the temp data matching by site and year
#   left_join(temp_data, by = c("PTAGIS_ID" = "Ptagis_ID", "Year" = "Year")) %>%
#   # glue the landcover data
#   left_join(landcover_data, by = c("PTAGIS_ID" = "Ptagis_ID", "Year" = "Year")) %>%
#   # glue the catchment shape data
#   left_join(catchment_data, by = c("PTAGIS_ID" = "Ptagis_ID")) %>%
#   
#   filter(rearing_type == "W")
# 
# head(master_parr_data)




# H1. WATERFLOW
#--------------------------------------------------------------------------
# 1. Sort the data to be wild only
#--------------------------------------------------------------------------
library(here) #directory setting
library(dplyr) #data manipulation toolbox (e.g. %>%, filter(), left_join())
library(janitor)
library(corrplot)
library(lubridate)
library(ggplot2)

here::i_am("precocious_parr_prelim_analyses_Suji.R")

parr_data <- read.csv(here("assembled", "idaho_wild_fish_metadata_2026_02_06.csv")) %>% clean_names
density_data <- read.csv(here("assembled", "precocious_parr_m2.csv")) %>% clean_names
catchment_data <- read.csv(here("explanatory", "site_watershed_architecture.csv")) %>% clean_names
landcover_data <- read.csv(here("explanatory", "sample_lulc_proportions.csv")) %>% clean_names
temp_data <- read.csv(here("explanatory", "sample_modeled_temp_C.csv")) %>% clean_names

# Filters for records where the rearing type is wild
# I commented this out - to look for non-wild fish, the better way is to look at
# the individual fish records. The srr code will contain this information. Rear
# type was historically recorded on the metadata, but later transferred to the
# fish data. The NA values here don't mean not wild, they just mean the data
# are not recorded in this column. 
#  wild_idaho_metadata <- parr_data %>%
#    filter(rearing_type == "W")

# Merges data for analysis
# I commented this out too - due to a multiple match issue, R expanded this from
# 297 records to 4,242 records. It erroneously duplicated records.
#wild_parr_data <- wild_idaho_metadata %>%
#  left_join(density_data, by = c("event_site" = "ptagis_id")) %>%    #match the site name in "event_site" to the site name in "Ptagis_ID"
#  left_join(catchment_data, by = c("event_site" = "Ptagis_ID"))
  
# You shouldn't really need the metadata - site and year data are already
# associated with the parr densities
# Joins the explanatory variables with the parr density data
  wild_parr_data <- density_data %>%
    left_join(catchment_data) %>%
    left_join(landcover_data) %>%
    left_join(temp_data)

#--------------------------------------------------------------------------
#  Let's take a look at the relationships of the potential predictor variables
#--------------------------------------------------------------------------
  
# Builds a correlation matrix
# We use the pairwise complete observations argument because we do have missing
# temperature data in more recent years
  explanatory_cors <- cor(wild_parr_data[, 5:34], use = "pairwise.complete.obs")
  
# Correlogram
  corrplot(explanatory_cors, col = magma(30))

#--------------------------------------------------------------------------
# 2. Linear regression model
#     ~ = "predicted by"
#--------------------------------------------------------------------------

# Constructs a model of how well slope explains precocious parr density
# Corrected column names after using clean_names before I ran this
  flow_model <- lm(prec_parr_m2 ~ slope, data = wild_parr_data)    #lm(): linear model; ~ = predicted by (it's asking is the density of preco parr predicted by the slope of the river)

#--------------------------------------------------------------------------
# 3. Result and visualization
#--------------------------------------------------------------------------
  
# Takes a look at the text summary
  summary(flow_model)

# Plots the results
# Nice plot btw!
  ggplot(wild_parr_data, aes(x = slope, y = prec_parr_m2)) + 
    geom_point(alpha = 0.6, color = "purple") + 
    geom_smooth(method = "lm", color = "black", se = TRUE) + 
    theme_minimal() +
    labs(title = "Effect of Waterflow Speed on Wild Precocious Parr Density",
         x = "Stream Steepness / Water Speed (Slope)",
         y = "Wild Parr Density (fish per m2)")




# H2. EMBARKMENT
#--------------------------------------------------------------------------
# 1. linear regression model base on the Shape variable & result
#--------------------------------------------------------------------------
  
# Constructs the shape model
  shape_model <- lm(prec_parr_m2 ~ shape, data = wild_parr_data)

# Summarizes the text results
  summary(shape_model)

#--------------------------------------------------------------------------
# 2. visualization
#--------------------------------------------------------------------------
  
# Plots the shape model
# Edited the title to help out a bit, from riverbed to watershed
ggplot(wild_parr_data, aes(x = shape, y = prec_parr_m2)) + 
  geom_point(alpha = 0.5, color = "darkblue") + 
  geom_smooth(method = "lm", color = "black", se = TRUE) + 
  theme_minimal() +
  labs(title = "Influence of Watershed Shape on Wild Precocious Parr Density",
       x = "Riverbed / Valley Shape Metric",
       y = "Wild Parr Density (fish per m2)")
  

  
  
# H3. CANOPY COVER
#--------------------------------------------------------------------------
# 1. Bring the landcover and join into wild_parr_data
#--------------------------------------------------------------------------
# Commented out - this is now incorporated earlier in the code
#wild_parr_data <- wild_parr_data %>%
#  left_join(landcover_data, by = c("event_site" = "Ptagis_ID"))

#--------------------------------------------------------------------------
# 2. Linear regression with NLCD_42 (evergreen forset)
#--------------------------------------------------------------------------
forest_model <- lm(prec_parr_m2 ~ nlcd_42, data = wild_parr_data)

#--------------------------------------------------------------------------
# 3. Result & visualization
#--------------------------------------------------------------------------
summary(forest_model)

ggplot(wild_parr_data, aes(x = nlcd_42, y = prec_parr_m2)) + 
  geom_point(alpha = 0.5, color = "darkgreen") + 
  geom_smooth(method = "lm", color = "black", se = TRUE) + 
  theme_minimal() +
  labs(title = "Effect of Evergreen Canopy Cover on Wild Precocious Parr Density",
       x = "Proportion of Evergreen Forest (NLCD_42)",
       y = "Wild Parr Density (fish per m2)")






# H4. 
#--------------------------------------------------------------------------
# 1. 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# 1. 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# 1. 
#--------------------------------------------------------------------------






# H5. 
#--------------------------------------------------------------------------
# 1. 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# 1. 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# 1. 
#--------------------------------------------------------------------------







# H6. 
#--------------------------------------------------------------------------
# 1. 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# 1. 
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# 1. 
#--------------------------------------------------------------------------
