# Sorting the data + making a master file ("model_df") (og: only for H1 -> updated to accommodate H1~5)
#--------------------------------------------------------------------------
library(here)    # directory setting
library(dplyr)   # data manipulation (%>%, filter(), left_join(), mutate())
library(ggplot2) # plotting

density_data    <- read.csv(here("assembled", "parr_density_ha.csv"))
catchment_data  <- read.csv(here("explanatory", "site_watershed_architecture.csv"))
landcover_data  <- read.csv(here("explanatory", "sample_lulc_proportions.csv"))

model_df <- density_data %>%                                    # model_df = master file; "df" = data frame (rows and columns)
  left_join(catchment_data, by = "Ptagis_ID") %>%               # join on site-only (not thinking the changes of the catchment)
  left_join(landcover_data, by = c("Ptagis_ID", "Sample_Year" = "Year"))                # join on site

model_df <- model_df %>%
  mutate(
    sediment_risk = NLCD_81 + NLCD_82 + NLCD_21 + NLCD_22 + NLCD_23 + NLCD_24,
    lwd_proxy     = NLCD_41 + NLCD_42 + NLCD_43
  )


# Screening the distribution + log transformation
#--------------------------------------------------------------------------
hist(model_df$prec_parr_ha, breaks = 30)
mean(model_df$prec_parr_ha == 0)          # how many zeros; creates TRUE or FALSE for every row (0.6 = 60% are zero)

# transform
model_df <- model_df %>%
  mutate(log_prec_parr = log1p(prec_parr_ha))

hist(model_df$log_prec_parr, breaks = 30) # recheck the shape
# result: skewed fixed by log, but log cannot fix the piling zeros
#                                             0.227451 of zeros;mean(model_df$prec_parr_ha == 0)



# Correlagram
#--------------------------------------------------------------------------
library(corrplot)
library(viridisLite)

# picking the numeric predictor colums for data frame
predictor_cols <- c("Slope", "TDA_km2", "MeanElev", "Shape",
                    "NLCD_41", "NLCD_42", "NLCD_52", "NLCD_71", "NLCD_81")
explanatory_cors <- cor(model_df[, predictor_cols],
                        use = "pairwise.complete.obs")
corrplot(explanatory_cors, col = magma(30)) 
round(explanatory_cors, 2)
# result (anything that is above |0.5|)
# Slope and NLCD_41 = strong positive correlation (0.6); deciduous forest a bit more common on steeper sites.
# TDA and Mean Elevation = a strong negative correlation (-0.8~ -1.0); larger-drainage sites sit at lower elevation, smaller-drainage sites sit high up
# NLCD_41 and NLCD_52 = strong positive correlation (0.6); deciduous forest and shrub track together somewhat.
# NLCD_42 and NLCD_52 (_71 is a bit more blue; less negative) = strong negative correlation (-0.8~-1.0); evergreen forest and shrub/scrub has inverse relationship
# burned areas convert forest (42) to shrub (52)







# H1. WATERFLOW | density predicted by slope (proxy for water speed)
#--------------------------------------------------------------------------
# 1. Linear regression model
#     ~ = "predicted by"
#--------------------------------------------------------------------------
flow_model <- lm(log_prec_parr ~ Slope, data = model_df)    

#--------------------------------------------------------------------------
# 2. Result and visualization
#--------------------------------------------------------------------------
summary(flow_model)

par(mfrow = c(2,2)); plot(flow_model); par(mfrow = c(1,1))  # splits the plot window into a 2×2 grid; all four diagnostic plots show at once

library(ggplot2)

ggplot(model_df, aes(x = Slope, y = prec_parr_ha)) + 
  geom_point(alpha = 0.6, color = "purple") + 
  geom_smooth(method = "lm", color = "black", se = TRUE) + 
  theme_minimal() +
  labs(title = "Effect of Waterflow Speed on Wild Precocious Parr Density",
       x = "Stream Steepness / Water Speed (Slope)",
       y = "Wild Parr Density (fish per m2)")




# H2-1. BASIN SHAPE | density predicted by watershed/basin shape
# #--------------------------------------------------------------------------
# # 1. linear regression model base on the Shape variable
# #--------------------------------------------------------------------------
# basin_model <- lm(prec_parr_ha ~ Shape, data = model_df)   # !!shouldn't use Shape to talk about cross-section, since Shape is about watershed/basin
# 
# #--------------------------------------------------------------------------
# # 2. Result and visualization
# #--------------------------------------------------------------------------
# summary(basin_model)
# 
# library(ggplot2)
# 
# ggplot(model_df, aes(x = Shape, y = prec_parr_ha)) + 
#   geom_point(alpha = 0.5, color = "darkblue") + 
#   geom_smooth(method = "lm", color = "black", se = TRUE) + 
#   theme_minimal() +
#   labs(title = "Influence of Watershed Shape on Wild Precocious Parr Density",
#        x = "Watershed / Basin Shape Metric",
#        y = "Wild Parr Density (fish per m2)")

#==========================================================================

# H2-2. CHANNEL SHAPE | density predicted by cross-section of valley/channel
#--------------------------------------------------------------------------
# 1. linear regression model base on the proxy variable (no direct data available to test cross-section)
#--------------------------------------------------------------------------
confinement_model <- lm(log_prec_parr ~ scale(Slope) + scale(TDA_km2), data = model_df)

#--------------------------------------------------------------------------
# 2. Result and visualization
#--------------------------------------------------------------------------
summary(confinement_model)

par(mfrow = c(2,2)); plot(confinement_model); par(mfrow = c(1,1))

library(ggplot2)

# Slope
ggplot(model_df, aes(x = Slope, y = prec_parr_ha)) +
  geom_point(alpha = 0.6, color = "tan4") +
  geom_smooth(method = "lm", color = "black", se = TRUE) +
  theme_minimal() +
  labs(title = "Channel Confinement Proxy: Slope vs Parr Density",
       x = "Stream Slope (steeper = more confined / V-shaped)",
       y = "Wild Parr Density (fish per m2)")

# Drainage area
ggplot(model_df, aes(x = TDA_km2, y = prec_parr_ha)) +
  geom_point(alpha = 0.6, color = "darkorange3") +
  geom_smooth(method = "lm", color = "black", se = TRUE) +
  theme_minimal() +
  labs(title = "Channel Confinement Proxy: Drainage Area vs Parr Density",
       x = "Total Drainage Area (km2) — larger = wider valley",
       y = "Wild Parr Density (fish per m2)")

# Elevation
ggplot(model_df, aes(x = MeanElev, y = prec_parr_ha)) +
  geom_point(alpha = 0.6, color = "steelblue4") +
  geom_smooth(method = "lm", color = "black", se = TRUE) +
  theme_minimal() +
  labs(title = "Channel Confinement Proxy: Elevation vs Parr Density",
       x = "Mean Elevation (m)",
       y = "Wild Parr Density (fish per m2)")



# H3-1. CANOPY COVER | density predicted by evergreen forest (NLCD_42)
#--------------------------------------------------------------------------
# 1. Linear regression with NLCD_42 (evergreen forset)
#--------------------------------------------------------------------------
forest_model <- lm(log_prec_parr ~ NLCD_42, data = model_df)

#--------------------------------------------------------------------------
# 2. Result & visualization
#--------------------------------------------------------------------------
summary(forest_model)

par(mfrow = c(2,2)); plot(forest_model); par(mfrow = c(1,1))

library(ggplot2)

ggplot(model_df, aes(x = NLCD_42, y = prec_parr_ha)) + 
  geom_point(alpha = 0.5, color = "darkgreen") + 
  geom_smooth(method = "lm", color = "black", se = TRUE) + 
  theme_minimal() +
  labs(title = "Effect of Evergreen Canopy Cover on Wild Precocious Parr Density",
       x = "Proportion of Evergreen Forest (NLCD_42)",
       y = "Wild Parr Density (fish per m2)")


# H3-2. CANOPY COVER | density predicted by wild fire
#--------------------------------------------------------------------------
# 1. Linear regression with NLCD_52 (shrub/scrub) and NLCD_71 (grassland/herbaceous)
#--------------------------------------------------------------------------
model_df <- model_df %>%
  mutate(
    fire_proxy = NLCD_52 + NLCD_71      # shrub/scrub + grassland
  )

fire_model <- lm(log_prec_parr ~ fire_proxy, data = model_df)

#--------------------------------------------------------------------------
# 2. Result & visualization
#--------------------------------------------------------------------------
summary(fire_model)

par(mfrow = c(2,2)); plot(fire_model); par(mfrow = c(1,1))

library(ggplot2)

ggplot(model_df, aes(x = fire_proxy, y = prec_parr_ha)) +
  geom_point(alpha = 0.6, color = "firebrick") +
  geom_smooth(method = "lm", color = "black", se = TRUE) +
  theme_minimal() +
  labs(title = "Post-Disturbance Cover (Fire Proxy) vs Wild Precocious Parr Density",
       x = "Shrub + Grassland Proportion (proxy for burned/open terrain)",
       y = "Wild Parr Density (fish per m2)")




# H4. SEDIMENT & LWD | used proxy
#                      Proxyed sediment risk with low slope + watershed disturbance due to agriculture practices and land development.
#                      Proxyed LWD with forest cover
#--------------------------------------------------------------------------
# 1. multiple regression with sediment_risk, lwd_proxy, slope
#--------------------------------------------------------------------------
sediment_lwd_model <- lm(log_prec_parr ~ sediment_risk + lwd_proxy + Slope,
                         data = model_df)
#--------------------------------------------------------------------------
# 2. Result & visualization
#--------------------------------------------------------------------------
summary(sediment_lwd_model)

par(mfrow = c(2,2)); plot(sediment_lwd_model); par(mfrow = c(1,1))


library(ggplot2)

ggplot(model_df, aes(x = sediment_risk, y = prec_parr_ha)) +
  geom_point(alpha = 0.6, color = "sienna") +
  geom_smooth(method = "lm", color = "black", se = TRUE) +
  theme_minimal() +
  labs(title = "Effect of Watershed Sediment Risk on Wild Precocious Parr Density",
       x = "Sediment-Risk Proxy (cropland + pasture + developed cover)",
       y = "Wild Parr Density (fish per m2)")

ggplot(model_df, aes(x = lwd_proxy, y = prec_parr_ha)) +
  geom_point(alpha = 0.6, color = "saddlebrown") +
  geom_smooth(method = "lm", color = "black", se = TRUE) +
  theme_minimal() +
  labs(title = "Effect of Forest-Cover (LWD Proxy) on Wild Precocious Parr Density",
       x = "LWD Proxy (proportion forest cover)",
       y = "Wild Parr Density (fish per m2)")






# H5. CHLOROPHYLL A
#--------------------------------------------------------------------------
# 1. Get the data from National Water Quality Monitoring Council (https://www.waterqualitydata.us/)
#--------------------------------------------------------------------------
library(dataRetrieval)
install.packages("dataRetrieval")

chl_sites <- whatWQPsites(
  statecode = "US:16",                     # Idaho
  characteristicName = "Chlorophyll a"
)

#--------------------------------------------------------------------------
# 2. Adjust column names
#   (already checked the data availability (it is!) and that the column names were different from catchment_data)
#   (Used code: exists(chl_sites),
#               names(chl_sites),
#               names(catchment_data))
#--------------------------------------------------------------------------
library(dplyr)
chl_sites %>%
  summarise(
    n = n(),
    lat_min = min(LatitudeMeasure, na.rm = TRUE),
    lat_max = max(LatitudeMeasure, na.rm = TRUE),
    lon_min = min(LongitudeMeasure, na.rm = TRUE),
    lon_max = max(LongitudeMeasure, na.rm = TRUE)
  )

salmon_area <- chl_sites %>%
  filter(LatitudeMeasure  > 44.0 & LatitudeMeasure  < 44.7,
         LongitudeMeasure > -115.5 & LongitudeMeasure < -114.5)

salmon_area %>%
  select(MonitoringLocationIdentifier, 
         MonitoringLocationName,                # name 
         MonitoringLocationTypeName,            # stream/river vs. lake/reservoir
         LatitudeMeasure, LongitudeMeasure)

#Is there a matching data...??
