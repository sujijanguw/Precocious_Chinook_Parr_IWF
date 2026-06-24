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

here::i_am("precocious_parr_prelim_analyses_Suji.R")

parr_data <- read.csv(here("assembled", "idaho_wild_fish_metadata_2026_02_06.csv"))
density_data <- read.csv(here("assembled", "precocious_parr_m2.csv"))
catchment_data <- read.csv(here("explanatory", "site_watershed_architecture.csv"))

wild_idaho_metadata <- parr_data %>%
  filter(rearing_type == "W")

wild_parr_data <- wild_idaho_metadata %>%
  left_join(density_data, by = c("event_site" = "Ptagis_ID")) %>%    #match the site name in "event_site" to the site name in "Ptagis_ID"
  left_join(catchment_data, by = c("event_site" = "Ptagis_ID"))


#--------------------------------------------------------------------------
# 2. Linear regression model
#     ~ = "predicted by"
#--------------------------------------------------------------------------
flow_model <- lm(prec_parr_m2 ~ Slope, data = wild_parr_data)    #lm(): linear model; ~ = predicted by (it's asking is the density of preco parr predicted by the slope of the river)

#--------------------------------------------------------------------------
# 3. Result and visualization
#--------------------------------------------------------------------------
summary(flow_model)

library(ggplot2)

ggplot(wild_parr_data, aes(x = Slope, y = prec_parr_m2)) + 
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
shape_model <- lm(prec_parr_m2 ~ Shape, data = wild_parr_data)

summary(shape_model)

#--------------------------------------------------------------------------
# 2. visualization
#--------------------------------------------------------------------------
ggplot(wild_parr_data, aes(x = Shape, y = prec_parr_m2)) + 
  geom_point(alpha = 0.5, color = "darkblue") + 
  geom_smooth(method = "lm", color = "black", se = TRUE) + 
  theme_minimal() +
  labs(title = "Influence of Riverbed Shape on Wild Precocious Parr Density",
       x = "Riverbed / Valley Shape Metric",
       y = "Wild Parr Density (fish per m2)")






# H3. CANOPY COVER
#--------------------------------------------------------------------------
# 1. Bring the landcover and join into wild_parr_data
#--------------------------------------------------------------------------
landcover_data <- read.csv(here("explanatory", "sample_lulc_proportions.csv"))

wild_parr_data <- wild_parr_data %>%
  left_join(landcover_data, by = c("event_site" = "Ptagis_ID"))

#--------------------------------------------------------------------------
# 2. Linear regression with NLCD_42 (evergreen forset)
#--------------------------------------------------------------------------
forest_model <- lm(prec_parr_m2 ~ NLCD_42, data = wild_parr_data)

#--------------------------------------------------------------------------
# 3. Result & visualization
#--------------------------------------------------------------------------
summary(forest_model)

ggplot(wild_parr_data, aes(x = NLCD_42, y = prec_parr_m2)) + 
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
