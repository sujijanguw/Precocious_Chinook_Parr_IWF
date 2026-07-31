# ==============================================================================
# PRECOCIOUS PARR; ENVIRONMENTAL DRIVERS ANALYSIS
# Suji Jang | last updated: 2026-07-14
# ==============================================================================
# CONTENTS
#   00. Setup ................. libraries, paths, helper functions ...... MUST RUN FIRST!
#   01. Load & assemble ....... build model_df (density + predictors) ... MUST RUN FIRST!
#   02. Streamflow ............ flow_all + hydrograph figures
#   03. Spatial ............... river network + site distance matrix
#   04. Screening ............. response distribution + log transform
#   05. Correlogram ........... collinearity check among predictors
#   06. Two-part model ........ presence (glm) + abundance (Gamma glm)
#   07. LASSO ................. penalized variable selection (glmnet)
#   08. Hypotheses ............ H1–H6 individual regressions
# ==============================================================================






# MUST RUN 00. SETUP + 01. LOAD & ASSEMBLE DATA "BEFORE" ANYTHING!!!!
# ==============================================================================
# 00. SETUP --------------------------------------------------------------------
# install.packages(c("here","dplyr","ggplot2","sf","fst","riverdist",
#                  "vegan","corrplot","viridisLite","glmnet","pscl","car"))


# Sort the data + making a master file ("model_df") (og: only for H1 -> updated to accommodate H1~5)
library(here)    # directory setting
library(dplyr)   # data manipulation (%>%, filter(), left_join(), mutate())
library(ggplot2) # plotting

options(scipen = 999)   # no scientific notation; no 1e+2

# set the folder
proj <- function(...) here("Desktop", "Precocious_Chinook_Parr_IWF", ...)

# set the standardization function
standardize <- function(x) (x - mean(x, na.rm = TRUE))/sd(x, na.rm = TRUE)
# ==============================================================================




# ==============================================================================
# 01. LOAD & ASSEMBLE --------------------------------------------------------
# model_df = master table. Density is the response; everything else joins on.
#    - catchment.        : static site geomorphology -> join by site only
#    - land cover / temp : vary by year              -> join by site + year

density_data    <- read.csv(proj("assembled",   "parr_density_ha.csv"))
catchment_data  <- read.csv(proj("explanatory", "site_watershed_architecture.csv"))
landcover_data  <- read.csv(proj("explanatory", "sample_lulc_proportions.csv"))
site_data       <- read.csv(proj("meta",        "sites.csv"))
temp_data       <- read.csv(proj("explanatory", "sample_modeled_temp_C.csv"))

model_df <- density_data %>%                                    
  left_join(catchment_data, by = "Ptagis_ID") %>%              
  left_join(landcover_data, by = c("Ptagis_ID", "Sample_Year" = "Year")) %>%    
  left_join(temp_data, by = c("Ptagis_ID", "Sample_Year" = "Year")) %>%           
  mutate(
    # proxy predictors built from NLCD classes
    sediment_risk = NLCD_81 + NLCD_82 + NLCD_21 + NLCD_22 + NLCD_23 + NLCD_24,
    lwd_proxy     = NLCD_41 + NLCD_42 + NLCD_43,
    # log response (for LASSO regression testing)
    log_prec_parr = log1p(prec_parr_ha))     # log1p = ln(1+x); good for data with x = 0
# ==============================================================================





# ==============================================================================
# 02. STREAMFLOW 
# Natural Water Model daily flow (.fst). one row per COMID per day.
# Filter to our sites' COMIDs, stack, and label by Ptagis_ID.
library(sf)
library(fst)
library(dplyr)
library(ggplot2)
library(patchwork)

flow_files <-list.files(path = proj("nwm_3_0_WR_17"), 
                        pattern = "\\.fst$", full.names = TRUE)   # full.names = FALSE gives just the file names; TRUE gives the directory

my_comids <- site_data$COMID

flow_all <- lapply(flow_files, function(f) {
  read.fst(f, columns = c("COMID", "date", "Q")) %>%
    filter(COMID %in% my_comids)
}) %>%
  bind_rows() %>%
  left_join(site_data %>% select(Ptagis_ID, COMID), by = "COMID") %>%
  mutate(date = as.Date(date))

# mean daily flow per site, per year (one value per site-year)-----------------
flow_site_year <- flow_all %>%
  mutate(year = as.integer(format(date, "%Y"))) %>%
  group_by(Ptagis_ID, year) %>%
  summarise(
    mean_Q = mean(Q, na.rm = TRUE),
    n_days = n(),
    .groups = "drop"
  )

# CHECK! 
unique(flow_all$Ptagis_ID)                 # shows the sites WITH flow
sort(unique(format(flow_all$date, "%Y")))  # shows the years present

# ---FIGURE 1. Daily Streamflow by Site (1979-2023)-----------------------------
ggplot(flow_all, aes(x = date, y = Q)) +
  geom_line(color = "steelblue", linewidth = 0.3) +
  facet_wrap(~ Ptagis_ID, ncol = 2, scales = "free_y") +
  theme_minimal() +
  labs(title = "Daily Streamflow by Site (1979-2023)", x = "Year", 
       y = "Discharge (Q)")

# ---FIGURE 2. mean annual flow per site (the modeled summary)------------------
ggplot(flow_site_year, aes(x = year, y = mean_Q)) +
  geom_line(color = "darkorange3", linewidth = 0.5) +
  geom_point(color = "black", size = 0.8) +
  facet_wrap(~ Ptagis_ID, ncol = 2, scales = "free_y") +
  theme_minimal() +
  labs(title = "Mean Annual Flow by Site (1979–2023)",
       subtitle = "Each point = one site-year's average daily flow (the value that enters the model)",
       x = "Year", y = "Mean Daily Discharge (Q)")

# ---FIGURE 3. daily flow for ONE site + ONE year, with its annual mean---------
# change these two to look at any site-year:
pick_site <- "VALEYC"
pick_year <- "2022"

one_site_year <- flow_all %>%
  filter(Ptagis_ID == pick_site,
         format(date, "%Y") == pick_year) %>%
  arrange(date)

annual_mean <- mean(one_site_year$Q, na.rm = TRUE)

ggplot(one_site_year, aes(x = date, y = Q)) +
  geom_line(color = "steelblue4", linewidth = 0.6) +
  geom_hline(yintercept = annual_mean, color = "firebrick",
             linetype = "dashed", linewidth = 0.8) +
  annotate("text", x = min(one_site_year$date), y = annual_mean,
           label = "annual mean", color = "firebrick",
           hjust = 0, vjust = -0.5, size = 3.5) +
  theme_minimal() +
  labs(title    = paste0("Daily Streamflow vs. Annual Mean — ", pick_site, ", ", pick_year),
       subtitle = "Red dashed = the single value that would enter the model",
       x = "Date", y = "Discharge (Q)")

# ---FIGURE 4. average flow for each calendar day, across all years (a site)--
# "typical" flow on Jan 1, Jan 2, ... Dec 31, averaged over 1979-2023.
pick_site <- "VALEYC"

flow_doy <- flow_all %>%                        # doy = day of year
  filter(Ptagis_ID == pick_site) %>%
  mutate(doy = format(date, "%m-%d")) %>%        
  filter(doy != "02-29") %>%
  group_by(doy) %>%
  summarise(
    mean_Q = mean(Q, na.rm = TRUE),
    n_years = n(),
    .groups = "drop"
  ) %>%
  mutate(doy_date = as.Date(paste0("2001-", doy)))

ggplot(flow_doy, aes(x = doy_date, y = mean_Q)) +
  geom_line(color = "seagreen4", linewidth = 0.6) +
  scale_x_date(date_labels = "%b", date_breaks = "1 month") +
  theme_minimal() +
  labs(title    = paste0("Average Flow by Calendar Day - ", pick_site, " (1979-2023)"),
       subtitle = "Each point = that day's flow averaged across all years (a typical-year hydrograph)",
       x = "Day of year", y = "Mean Discharge (Q)")

# ---FIGURE 5. average flow for each calendar day, across all years (ALL sites)-
# "typical" flow on Jan 1, Jan 2, ... Dec 31, averaged over 1979-2023.
all_sites <- sort(unique(flow_all$Ptagis_ID))

flow_doy <- flow_all %>%                        # doy = day of year
  filter(Ptagis_ID == all_sites) %>%
  mutate(doy = format(date, "%m-%d")) %>%        
  filter(doy != "02-29") %>%
  group_by(doy) %>%
  summarise(
    mean_Q = mean(Q, na.rm = TRUE),
    n_years = n(),
    .groups = "drop"
  ) %>%
  mutate(doy_date = as.Date(paste0("2001-", doy)))

ggplot(flow_doy, aes(x = doy_date, y = mean_Q)) +
  geom_line(color = "seagreen4", linewidth = 0.6) +
  scale_x_date(date_labels = "%b", date_breaks = "1 month") +
  theme_minimal() +
  labs(title    = paste0("Average Flow by Calendar Day - All Sites", " (1979-2023)"),
       x = "Day of year", y = "Mean Discharge (Q)")
# ==============================================================================




# ==============================================================================
# 03. SPATIAL
# Read stream/site shapefiles, sanity-check drainage area, then build a
# river-network distance matrix between sites (for the Mantel test in H6).
library(riverdist)
library(sf)

streams  <- st_read(proj("spatial", "Salmon_streams_5070.shp"))
sites_sf <- st_read(proj("spatial", "Sites_5070.shp"))

# quick map
plot(st_geometry(sites_sf), add = TRUE, col = "red", pch = 19)

# cross-check the shapefile drainage area vs. our TDA_km2
da_check <- st_drop_geometry(streams) %>%
  select(COMID, TotDASqKM) %>%
  filter(COMID %in% site_data$COMID) %>%
  left_join(site_data %>% select(COMID, Ptagis_ID), by = "COMID") %>%
  left_join(model_df %>% distinct(Ptagis_ID, TDA_km2), by = "Ptagis_ID") %>%
  mutate(difference = TotDASqKM - TDA_km2)

# --- FIGURE 1. River-network distance matrix ----------------------------------
salmon_net <- line2network(path  = proj("spatial"),
                           layer = "Salmon_streams_5070")
salmon_net <- cleanup(salmon_net)          
saveRDS(salmon_net, proj("salmon_net.RDS"))

salmon_net <- cleanup(salmon_net)
saveRDS(salmon_net, "salmon_net.RDS")

sites_xy <- sites_sf %>%
  st_drop_geometry() %>%
  select(Ptagis_ID, Lon_m, Lat_m)

sites_put <- xy2segvert(x = sites_xy$Lon_m, y = sites_xy$Lat_m,
                        rivers = salmon_net)

river_dmat <- riverdistancemat(seg  = sites_put$seg,
                               vert = sites_put$vert,
                               rivers = salmon_net)
rownames(river_dmat) <- sites_xy$Ptagis_ID
colnames(river_dmat) <- sites_xy$Ptagis_ID
# ==============================================================================










# Match the .fst + .shp based on COMID
#--------------------------------------------------------------------------
library(fst)
library(dplyr)
library(ggplot2)

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

# check the data to numeric (not charcter)
flow_all <- flow_all %>%
  mutate(date = as.Date(date))



# which sites do you have flow for?
unique(flow_all$Ptagis_ID)

# which years?
sort(unique(format(flow_all$date, "%Y")))



# pick ONE site and ONE year to show what daily flow looks like
one_site_year <- flow_all %>%
  filter(Ptagis_ID == "VALEYC",              # <- pick any site you like
         format(date, "%Y") == "2022") %>%    # <- pick any year present in the data
  arrange(date)

ggplot(one_site_year, aes(x = date, y = Q)) +
  geom_line(color = "steelblue4", linewidth = 0.6) +
  theme_minimal() +
  labs(
    title = "Daily streamflow at one site, one year",
    subtitle = "Valley Creek, 2022 — 365 daily values, but density is one number per site-year",
    x = "Date",
    y = "Discharge (Q)"
  )





annual_mean <- mean(one_site_year$Q, na.rm = TRUE)

ggplot(one_site_year, aes(x = date, y = Q)) +
  geom_line(color = "steelblue4", linewidth = 0.6) +
  geom_hline(yintercept = annual_mean, color = "firebrick",
             linetype = "dashed", linewidth = 0.8) +
  annotate("text", x = min(one_site_year$date), y = annual_mean,
           label = "annual mean", color = "firebrick",
           hjust = 0, vjust = -0.5, size = 3.5) +
  theme_minimal() +
  labs(
    title = "Daily streamflow vs. the annual summary",
    subtitle = "Valley Creek, 2022",
    x = "Date", y = "Discharge (Q)"
  )








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
# ==============================================================================









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
saveRDS(salmon_net, "salmon_net.RDS")

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
# ==============================================================================







# ==============================================================================

# Screening the distribution + log transformation
#--------------------------------------------------------------------------
library(ggplot2)

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




# ==============================================================================
# 07. LASSO -------------------------------------------------------------------
# helper: fit a standardized LASSO on a chosen predictor set, return everything
library(glmnet)
options(scipen = 999)

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

# keep the non-zero predictors
sds <- sapply(y_data[, x_data], sd, na.rm = TRUE)
x_data_keep <- x_data[is.finite(sds) & sds > 0]

# define response variable (for the "error")
y <- y_data$log_prec_parr



# define matrix of predictor variables (for the "penalty")
x <- as.matrix(as.data.frame(lapply(y_data[, x_data_keep], standardize)))

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

cv_model_2 <- cv.glmnet(x, y, alpha = 1)

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

# 4) x = 2) but only Q95 
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
