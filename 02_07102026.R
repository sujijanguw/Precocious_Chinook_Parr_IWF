# Sort the data + making a master file ("model_df") (og: only for H1 -> updated to accommodate H1~5)
#--------------------------------------------------------------------------
library(here)    # directory setting
library(dplyr)   # data manipulation (%>%, filter(), left_join(), mutate())
library(ggplot2) # plotting

density_data    <- read.csv(here("Desktop", "Precocious_Chinook_Parr_IWF", "assembled", "parr_density_ha.csv"))
catchment_data  <- read.csv(here("Desktop", "Precocious_Chinook_Parr_IWF", "explanatory", "site_watershed_architecture.csv"))
landcover_data  <- read.csv(here("Desktop", "Precocious_Chinook_Parr_IWF","explanatory", "sample_lulc_proportions.csv"))
site_data       <- read.csv(here("Desktop", "Precocious_Chinook_Parr_IWF","meta", "sites.csv"))
temp_data       <- read.csv(here("Desktop", "Precocious_Chinook_Parr_IWF", "explanatory", "sample_modeled_temp_C.csv"))

model_df <- density_data %>%                                    # model_df = master file; "df" = data frame (rows and columns)
  left_join(catchment_data, by = "Ptagis_ID") %>%               # join on site-only (not thinking the changes of the catchment)
  left_join(landcover_data, by = c("Ptagis_ID", "Sample_Year" = "Year")) %>%    # join on site
  left_join(temp_data, by = c("Ptagis_ID", "Sample_Year" = "Year")) %>%           # join on site and year
  mutate(
    sediment_risk = NLCD_81 + NLCD_82 + NLCD_21 + NLCD_22 + NLCD_23 + NLCD_24,
    lwd_proxy     = NLCD_41 + NLCD_42 + NLCD_43
  ) %>%
  mutate(log_prec_parr = log1p(prec_parr_ha))



# # Get the site location of Ptagis_id (using PTAGIS API)
# #--------------------------------------------------------------------------
# library(httr)
# 
# mmr <- httr::GET("https://api.ptagis.org/sites/mrr")
# str(mmr$content)
# 
# mmr_content <- httr::content(mmr, as = "text")
# str(mmr_content)
# 
# mmr_JSON <- jsonlite::fromJSON(mmr_content)
# 
# mmr_site <- data.frame(siteCode = sort(unique(model_df$Ptagis_ID))) # All of the Ptagis_id I have on the master data (model_df)
# mmr_site <- left_join(mmr_site, mmr_JSON, by = "siteCode")          # Ptagis_id info!





# # Add a column on master data (model_df) about the stream position (using Strahler Stream Order)
# #--------------------------------------------------------------------------
# library(nhdplusTools)
# library(sf)
# library(dplyr)
# 
# mmr_site$latitude <- as.numeric(mmr_site$latitude)
# mmr_site$longitude <- as.numeric(mmr_site$longitude)
# 
# site_info <- function(lat, lon) {
#   pt <- sf::st_sfc(sf::st_point(c(lon, lat)), crs = 4269)
#   comid <- tryCatch(discover_nhdplus_id(pt), error = function(e) NA)
#   if (is.na(comid)) return(data.frame(COMID = NA_integer_, stream_order = NA_integer_))
#   fl <- tryCatch(get_nhdplus(comid = comid), error = function(e) NULL)
#   order <- if (is.null(fl)) NA_integer_ else fl$streamorde[1]
#   data.frame(COMID = comid, stream_order = order)   # <-- returns BOTH now
# }
# 
# site_results <- do.call(rbind, mapply(site_info,
#                                       mmr_site$latitude,
#                                       mmr_site$longitude,
#                                       SIMPLIFY = FALSE))
# mmr_site <- cbind(mmr_site, site_results)
# 
# my_comids <- mmr_site$COMID
# 


# # Plot the MMR site longitude + latitude to create a map (for my sake)
# #--------------------------------------------------------------------------
# library(leaflet)
# library(htmlwidgets)
# 
# mmr_site <- mmr_site %>%
#   mutate(
#     popups = paste0(
#       "<strong> Site Code: </strong><br>", siteCode,
#       "</br><strong> Stream Name: </strong><br>",name,
#       "</br><strong> Stream Order: </strong><br>", stream_order
#     )
#   )
# 
# mmr_leaflet <- leaflet() %>%
#   addTiles() %>%    # adds the default OpenStreetMap background
#   addMarkers(lng = mmr_site$longitude, lat = mmr_site$latitude, popup = mmr_site$popups)
# 
# saveWidget(mmr_leaflet, file = here("Desktop", "Precocious_Chinook_Parr_IWF", "mmr_site.html"))      # Ptagis_id map!





# Read shape file
#--------------------------------------------------------------------------
library(sf)

streams <- st_read(here("Desktop", "Precocious_Chinook_Parr_IWF", "spatial",
                        "Salmon_streams_5070.shp"))

# Match the .fst + .shp based on COMID
#--------------------------------------------------------------------------
library(fst)
library(dplyr)

files <- list.files("Desktop/Precocious_Chinook_Parr_IWF/nwm_3_0_WR_17/", pattern = "\\.fst$", full.names = TRUE)

# read + filter each year to the MMR sites, then stack
my_comids <- site_data$COMID

flow_all <- lapply(files, function(f) {
  read.fst(f, columns = c("COMID", "date", "Q")) %>%
    filter(COMID %in% my_comids)
}) %>%
  bind_rows()

# label flow by PTAGIS_ID
flow_all <- flow_all %>%
  left_join(site_data %>% select(Ptagis_ID, COMID), by = "COMID")




# Get the elevation on DEM (Digital Elevation Model)
#--------------------------------------------------------------------------
library(sf)

streams <- st_read(here("Desktop", "Precocious_Chinook_Parr_IWF", "spatial",
                        "Salmon_streams_5070.shp"))
sites_sf <- st_read(here("Desktop", "Precocious_Chinook_Parr_IWF", "spatial",
                    "Sites_5070.shp"))

#geometry type (e.g. lines, points)
st_geometry_type(streams)[1]
st_geometry_type(sites_sf)[1]

plot(st_geometry(streams))
plot(st_geometry(sites_sf), add = TRUE, col ="red", pch = 19)


#compare the TotDASqKM to TDA_km2
library(dplyr)

streams_tbl <- st_drop_geometry(streams)

da_check <- streams_tbl %>%
  select(COMID, TotDASqKM) %>%
  filter(COMID %in% site_data$COMID) %>%
  left_join(site_data %>% select(COMID, Ptagis_ID), by = "COMID") %>%
  left_join(model_df %>% distinct(Ptagis_ID, TDA_km2), by = "Ptagis_ID") %>%
  mutate(difference = TotDASqKM - TDA_km2)





# Convert the network into a riverdist to get distances
#--------------------------------------------------------------------------
library(riverdist)
library(sf)

# riverdist needs the network as an shapefile it can read
salmon_net <- line2network(
  path = here::here("Desktop","Precocious_Chinook_Parr_IWF","spatial"),
  layer = "Salmon_streams_5070"
)

salmon_net <- cleanup(salmon_net)

# mouth/outlet = 2929
# st_drop_geometry(streams) %>%
#   arrange(desc(TotDASqKM)) %>%
#   select(COMID, GNIS_NAME, TotDASqKM) %>%
#   head() # from here I got the COMID with largest number
# 
# outlet_line <- streams %>% filter(COMID == 24938538)
# 
# outlet_coords <- st_coordinates(outlet_line)
# outlet_xy <- outlet_coords[nrow(outlet_coords), c("X","Y")]
# 
# outlet_snap <- xy2segvert(x = outlet_xy["X"],
#                           y = outlet_xy["Y"],
#                           rivers = salmon_net)
# outlet_snap$seg



# Get the site coordinates and put into the river network
sites_xy <- sites_sf %>%
  sf::st_drop_geometry() %>%
  dplyr::select(Ptagis_ID, Lon_m, Lat_m)

sites_put <- xy2segvert(
  x = sites_xy$Lon_m,
  y = sites_xy$Lat_m,
  rivers = salmon_net
)

# result
river_dmat <- riverdistancemat(
  seg = sites_put$seg,
  vert = sites_put$vert,
  rivers = salmon_net
)

rownames(river_dmat) <- sites_xy$Ptagis_ID
colnames(river_dmat) <- sites_xy$Ptagis_ID
river_dmat   

plot(salmon_net)
points(sites_xy$Lon_m, sites_xy$Lat_m, pch = 19, col = "red")









# Screening the distribution + log transformation
#--------------------------------------------------------------------------
hist(model_df$prec_parr_ha, breaks = 30)
mean(model_df$prec_parr_ha == 0)          # how many zeros; creates TRUE or FALSE for every row (0.22 = 22% are zero)
qqPlot(model_df$prec_parr_ha)       # raw normality check


# transform
model_df <- model_df %>%
  mutate(log_prec_parr = log1p(prec_parr_ha))

hist(model_df$log_prec_parr, breaks = 30) # recheck the shape
qqPlot(model_df$log_prec_parr)      # post-transform normality check
mean(model_df$prec_parr_ha); median(model_df$prec_parr_ha)   # skew via mean/median gap

# result: skewed fixed by log, but log cannot fix the piling zeros
#                                             0.227451 of zeros;mean(model_df$prec_parr_ha == 0)





# zero-inflated model
#--------------------------------------------------------------------------
library(pscl)

# Part 1. presence; what make a site a structural zero?
# zeroinfl() syntax: response/outcome ~ count_predictors | zero_inflation_predictors
# (pick predictors that are NOT on the same side in correlogram; no TDA_km2 + MeanElev OR NLCD_42 + NLCD_52)
model_df$present <- as.integer(model_df$prec_parr_ha > 0) # as.integer() converts TRUE/FALSE -> 0 or 1
presence_model <- glm(present ~ Slope + TDA_km2 + Q95,    # "present" = response!
                      family = binomial,                  # binomial = turns into 0/1 label
                      data = model_df)

# Part 2. density; how many? (continuous positive densities only)
positives <- subset(model_df, prec_parr_ha > 0)
density_model <- glm(prec_parr_ha ~ Slope + NLCD_42,   # count side
                     family = Gamma(link = "log"),
                     data = positives)

summary(presence_model)
summary(density_model)




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





# Lasso regression
#--------------------------------------------------------------------------
library(glmnet)

# 1) x = ALL
# ==============================================================================

x_data <- c('TDA_km2','MeanElev','Slope','Shape','Link',
            'CLink','DLink','NLCD_11','NLCD_12','NLCD_21',
            'NLCD_22','NLCD_23','NLCD_24','NLCD_31','NLCD_41',
            'NLCD_42', 'NLCD_43', 'NLCD_51','NLCD_52',
            'NLCD_71','NLCD_81','NLCD_82','NLCD_90','NLCD_95',
            'Q05','Q25','Q50','Q75','Q95','Mean',
            'sediment_risk','lwd_proxy')

# filter the x_data so that y and x have the SAME rows
y_data <- model_df[complete.cases(model_df[, c('log_prec_parr', x_data)]), ]

# define response variable (for the "error")
y <- y_data$log_prec_parr

# define matrix of predictor variables (for the "penalty")
x <- data.matrix(y_data[, x_data])

# perform k-fold cross-validation to find optimal lambda value
# cv.glmnet() defaults to 10-fold cross validation (k = 10)
# doing this will give many many models!
cv_model <- cv.glmnet(x, y, alpha = 1)


# read the exact lambda penalty that is at the bottom of the U-curve
coef(cv_model, s = "lambda.min")

# read the simplest lambda value that is still within 1 stnd. error of the absolute best
coef(cv_model, s = "lambda.1se")

# (result example)
# ==============================================================================
# > coef(cv_model, s = "lambda.min")
# 5 x 1 sparse Matrix of class "dgCMatrix"          # doesn't mean anything (just versions and stuff) :)
# lambda.min
# (Intercept) 476.273195            # Base Guess (U); if a car had zero mpg, 
#                                     wt (weight), drat (rear axle ratio), 
#                                     qsec (quarter-mile time), the baseline starting prediction is 476 hp
# mpg          -3.141508            # for 1 unit mpg goes UP, the predicted hp goes DOWN by 3.14
# wt           18.690256            # for 1 unit wt goes UP, the predicted hp goes UP by 18.7
#                                     (weight needs to be converted to compare with qsec)
# drat          .                   # weak variable (shrinked to zero!)
# qsec        -18.298316            # for 1 unit mpg goes UP, the predicted hp goes DOWN by 18.3
# ==============================================================================


# find optimal lambda value (that minimizes test MSE)
best_lambda <- cv_model$lambda.min


#produce plot of test MSE by lambda value
plot(cv_model) 


# 2) x = the “left” ones (except conflicting NLCD_41) + others
# ==============================================================================
x_data <- c('TDA_km2','Slope','Shape','Link',
            'CLink','DLink','NLCD_11','NLCD_12','NLCD_21',
            'NLCD_22','NLCD_23','NLCD_24','NLCD_31',
            'NLCD_42', 'NLCD_43', 'NLCD_51',
            'NLCD_71','NLCD_81','NLCD_82','NLCD_90','NLCD_95',
            'Q05','Q25','Q50','Q75','Q95','Mean',
            'sediment_risk','lwd_proxy')

y_data <- model_df[complete.cases(model_df[, c('log_prec_parr', x_data)]), ]

y <- y_data$log_prec_parr
x <- data.matrix(y_data[, x_data])

cv_model <- cv.glmnet(x, y, alpha = 1)

coef(cv_model, s = "lambda.min")
coef(cv_model, s = "lambda.1se")

best_lambda <- cv_model$lambda.min

plot(cv_model) 

# 3) x = "right" ones from correlation and the rest
# ==============================================================================
x_data <- c('MeanElev','Shape','Link',
            'CLink','DLink','NLCD_11','NLCD_12','NLCD_21',
            'NLCD_22','NLCD_23','NLCD_24','NLCD_31','NLCD_41',
            'NLCD_43', 'NLCD_51',
            'NLCD_71','NLCD_81','NLCD_82','NLCD_90','NLCD_95',
            'Q05','Q25','Q50','Q75','Q95','Mean',
            'sediment_risk','lwd_proxy')

y_data <- model_df[complete.cases(model_df[, c('log_prec_parr', x_data)]), ]

y <- y_data$log_prec_parr
x <- data.matrix(y_data[, x_data])

cv_model <- cv.glmnet(x, y, alpha = 1)

coef(cv_model, s = "lambda.min")
coef(cv_model, s = "lambda.1se")

best_lambda <- cv_model$lambda.min

plot(cv_model) 

# 4) x = "right" ones from correlation and the rest
# ==============================================================================
x_data <- c('TDA_km2','Slope','Shape','Link',
            'CLink','DLink','NLCD_11','NLCD_12','NLCD_21',
            'NLCD_22','NLCD_23','NLCD_24','NLCD_31',
            'NLCD_42', 'NLCD_43', 'NLCD_51',
            'NLCD_71','NLCD_81','NLCD_82','NLCD_90','NLCD_95',
            'Q95','Mean',
            'sediment_risk','lwd_proxy')

y_data <- model_df[complete.cases(model_df[, c('log_prec_parr', x_data)]), ]

y <- y_data$log_prec_parr
x <- data.matrix(y_data[, x_data])

cv_model <- cv.glmnet(x, y, alpha = 1)

coef(cv_model, s = "lambda.min")
coef(cv_model, s = "lambda.1se")

best_lambda <- cv_model$lambda.min

plot(cv_model) 


# 5) x = one from each
# ==============================================================================
x_data <- c('TDA_km2','Slope','Shape',
            'NLCD_42', 'NLCD_52',
            'NLCD_71','NLCD_81',
            'Q95','sediment_risk','lwd_proxy')

y_data <- model_df[complete.cases(model_df[, c('log_prec_parr', x_data)]), ]

y <- y_data$log_prec_parr
x <- data.matrix(y_data[, x_data])

cv_model <- cv.glmnet(x, y, alpha = 1)

coef(cv_model, s = "lambda.min")
coef(cv_model, s = "lambda.1se")

best_lambda <- cv_model$lambda.min

plot(cv_model) 





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






# # H5. CHLOROPHYLL A
# #--------------------------------------------------------------------------
# # 1. Get the data from National Water Quality Monitoring Council (https://www.waterqualitydata.us/)
# #--------------------------------------------------------------------------
# library(dataRetrieval)
# install.packages("dataRetrieval")
# 
# chl_sites <- whatWQPsites(
#   statecode = "US:16",                     # Idaho
#   characteristicName = "Chlorophyll a"
# )
# 
# #--------------------------------------------------------------------------
# # 2. Adjust column names
# #   (already checked the data availability (it is!) and that the column names were different from catchment_data)
# #   (Used code: exists(chl_sites),
# #               names(chl_sites),
# #               names(catchment_data))
# #--------------------------------------------------------------------------
# library(dplyr)
# chl_sites %>%
#   summarise(
#     n = n(),
#     lat_min = min(LatitudeMeasure, na.rm = TRUE),
#     lat_max = max(LatitudeMeasure, na.rm = TRUE),
#     lon_min = min(LongitudeMeasure, na.rm = TRUE),
#     lon_max = max(LongitudeMeasure, na.rm = TRUE)
#   )
# 
# salmon_area <- chl_sites %>%
#   filter(LatitudeMeasure  > 44.0 & LatitudeMeasure  < 44.7,
#          LongitudeMeasure > -115.5 & LongitudeMeasure < -114.5)
# 
# salmon_area %>%
#   select(MonitoringLocationIdentifier, 
#          MonitoringLocationName,                # name 
#          MonitoringLocationTypeName,            # stream/river vs. lake/reservoir
#          LatitudeMeasure, LongitudeMeasure)
# 
# #Is there a matching data...??






# H6. RIVER DISTANCE
# (testing if sites close togerhte by river have similar prec parr densities)
#--------------------------------------------------------------------------
install.packages("vegan")
library(vegan)   # mantel() function

# one density value per site
site_density <- model_df %>%
  group_by(Ptagis_ID) %>%
  summarise(mean_log_parr = mean(log_prec_parr, na.rm = TRUE)) %>%
  ungroup()

# Put sites in the SAME order as river_dmat rows/cols
site_order <- rownames(river_dmat)
site_density <- site_density %>%
  slice(match(site_order, Ptagis_ID))   # reorder to match the matrix

# Show how different each pair in density is
density_dmat <- as.matrix(dist(site_density$mean_log_parr))
rownames(density_dmat) <- site_density$Ptagis_ID
colnames(density_dmat) <- site_density$Ptagis_ID

# Mantel test: does river distance correlate with density difference?
mantel_result <- mantel(as.dist(river_dmat), as.dist(density_dmat),
                        method = "pearson", permutations = 999)
