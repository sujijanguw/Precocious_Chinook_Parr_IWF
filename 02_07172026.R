# ==============================================================================
# PRECOCIOUS PARR; ENVIRONMENTAL DRIVERS ANALYSIS
# Suji Jang | last updated: 2026-07-14
# ==============================================================================
# CONTENTS
#   00. Setup ................... libraries, paths, helper functions ...... MUST RUN FIRST!
#   01. Load & assemble ......... build model_df (density + predictors) ... MUST RUN FIRST!
#   02. Streamflow .............. flow_all + hydrograph figures
#   03. Spatial ................. river network + site distance matrix
#   04. Screening ............... response distribution + log transform
#   05. Correlogram ............. collinearity check among predictors
#   06. Two-part model .......... presence (glm) + abundance (Gamma glm)
#   07. LASSO ................... penalized variable selection (glmnet)
#   08. ADULT:JACK RATIO ........ (preliminary data analysis) 
#   09. LANDCOVER PERC .......... (preliminary data analysis) coverage per site / per year  
#   10. FISH TAG ................ (preliminary data analysis) add year
#   11. Initial Hypotheses ...... H1–H6 individual regressions
#   12. EM Model ................ Early Maturation model
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

library(dplyr)

density_data    <- read.csv(proj("assembled",   "parr_density_ha.csv"))
catchment_data  <- read.csv(proj("explanatory", "site_watershed_architecture.csv"))
landcover_data  <- read.csv(proj("explanatory", "sample_lulc_proportions.csv"))
site_data <- read.csv(proj("meta", "site_key.csv")) %>% select(-Old) %>%
  left_join(read.csv(proj("meta", "sites.csv")) %>% select(-Name), by = "Ptagis_ID") %>%
  full_join(read.csv(proj("explanatory", "stream_morphology.csv")), by = "Ptagis_ID") %>%
  relocate(Ptagis_ID)
temp_data       <- read.csv(proj("explanatory", "sample_modeled_temp_C.csv"))
meta_data       <- read.csv(proj("meta",        "idaho_wild_fish_metadata_2026_06_24.csv"))


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
       x = "Day of year", y = "Mean Discharge (Q)")

# ---FIGURE 5. average flow for each calendar day, across all years (multiple sites)
# "typical" flow on Jan 1, Jan 2, ... Dec 31, averaged over 1979-2023.
all_sites <- sort(unique(flow_all$Ptagis_ID))
pick_sites <- c("HERDC", "CHAMWF", "ELKC")

flow_doy <- flow_all %>%                        
  filter(Ptagis_ID %in% pick_sites) %>%
  mutate(doy = format(date, "%m-%d")) %>%        
  filter(doy != "02-29") %>%
  group_by(Ptagis_ID, doy) %>%
  summarise(
    mean_Q = mean(Q, na.rm = TRUE),
    n_years = n(),
    .groups = "drop"
  ) %>%
  mutate(doy_date = as.Date(paste0("2001-", doy)))

ggplot(flow_doy, aes(x = doy_date, y = mean_Q, color = Ptagis_ID)) +
  geom_line(linewidth = 0.6) +
  scale_x_date(date_labels = "%b", date_breaks = "1 month") +
  theme_minimal() +
  labs(title    = "Average Flow by Calendar Day (1979-2023)",
       x = "Day of year", 
       y = "Mean Discharge (Q)",
       color = "Site ID") 
# ==============================================================================





# ==============================================================================
# 03. SPATIAL
# 1. Read stream/site shapefiles, sanity-check drainage area, then build 
#    a river-network distance matrix between sites (for the Mantel test in H6).
# 2. Build a site map

library(riverdist)
library(sf)

# 1. Build a river-network distance matrix between sites
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


# 2. Site map
# --- FIGURE 2. MMR Site Map ---------------------------------------------------
site_meta <- tibble::tribble(
  ~Ptagis_ID, ~Fork,            ~site_label,                        ~Feeds,
  "VALEYC",   "Upper Salmon",   "Valley Creek",               "Salmon River mainstem (Stanley)",
  "CAPEHC",   "Upper Salmon",   "Cape Horn Creek",            "upper Salmon (high-elev trib)",
  "HERDC",    "Upper Salmon",   "Herd Creek",                 "East Fork Salmon (heavy sediment)",
  "BEARVC",   "Middle Fork",    "Bear Valley Creek",          "forms Middle Fork w/ Marsh Ck",
  "MARSHC",   "Middle Fork",    "Marsh Creek",                "forms Middle Fork w/ Bear Valley",
  "ELKC",     "Middle Fork",    "Elk Creek",                  "Bear Valley Creek",
  "SULFUC",   "Middle Fork",    "Sulphur Creek",              "Middle Fork (upper-middle)",
  "LOONC",    "Middle Fork",    "Loon Creek",                 "Middle Fork",
  "CAMASC",   "Middle Fork",    "Camas Creek",                "Middle Fork (from the east)",
  "BIGC",     "Middle Fork",    "Big Creek (main/trap)",      "Middle Fork (largest trib)",
  "BIG2C",    "Middle Fork",    "Big Creek (upper array)",    "Middle Fork (largest trib)",
  "SALRSF",   "South Fork",     "South Fork Salmon River",    "Salmon River mainstem",
  "SECESR",   "South Fork",     "Secesh River",               "South Fork Salmon",
  "LAKEC",    "South Fork",     "Lake Creek",                 "Secesh River",
  "CHAMBC",   "Lower Mainstem", "Chamberlain Creek",          "Salmon River mainstem (flows N)",
  "CHAMWF",   "Lower Mainstem", "W. Fork Chamberlain Creek",  "Chamberlain Creek"
)

# join metadata onto the shapefile 
sites_map <- sites_sf %>% left_join(site_meta, by = "Ptagis_ID")
mainstem <- streams %>% filter(GNIS_NAME == "Salmon River")

# mapping
library(ggplot2)
library(ggrepel)   

ggplot() +
  geom_sf(data = streams,  color = "grey80", linewidth = 0.3) +
  geom_sf(data = mainstem, color = "steelblue3", linewidth = 1.2) +   # mainstem highlighted
  geom_sf(data = sites_map, aes(color = Fork), size = 3) +
  geom_text_repel(data = sites_map,
                  aes(geometry = geometry, label = site_label, color = Fork),
                  stat = "sf_coordinates", size = 2.8,
                  max.overlaps = 20, show.legend = FALSE) +
  scale_color_brewer(palette = "Dark2") +
  theme_minimal() +
  labs(title    = "Sites: Salmon River Basin",
       subtitle = "Mainstem in blue; sites colored by fork",
       color    = "Fork")
# ==============================================================================





# ==============================================================================
# 04. SCREENING
# Check the response shape before modeling. Raw density is right-skewed with
# many zeros; log1p fixes the skew (but NOT the zeros — see Section 06).

hist(model_df$prec_parr_ha, breaks = 30)
qqPlot(model_df$prec_parr_ha)                    # raw: curves off the line
mean(model_df$prec_parr_ha == 0)                 # ~0.23 -> 23% zeros

hist(model_df$log_prec_parr, breaks = 30)        # post-transform shape
qqPlot(model_df$log_prec_parr)                   # log: hugs the line better
mean(model_df$prec_parr_ha); median(model_df$prec_parr_ha)   # mean >> median
# ==============================================================================





# ==============================================================================
# 05. CORRELOGRAM
# Screen predictors for collinearity BEFORE multi-predictor models.

library(corrplot)
library(viridisLite)

predictor_cols <- c("Slope", "TDA_km2", "MeanElev", "Shape",
                    "NLCD_41", "NLCD_42", "NLCD_52", "NLCD_71", "NLCD_81")
explanatory_cors <- cor(model_df[, predictor_cols], use = "pairwise.complete.obs")

corrplot(explanatory_cors, col = magma(30))
round(explanatory_cors, 2)

# Strong pairs (|r| > 0.5):
#   TDA_km2  <-> MeanElev : strong NEG  (big drainage sits low; small sits high)
#   NLCD_42  <-> NLCD_52  : strong NEG  (evergreen vs shrub — fire conversion)
#   Slope    <-> NLCD_41  : POS ~0.6
#   NLCD_41  <-> NLCD_52  : POS ~0.6
# -> don't put both members of a strong pair in the same model.
# ==============================================================================





# ==============================================================================
# 06. HURDLE MODEL (two parts); used for data with an unusually high number of zeros.
# The 23% zeros mean density comes from two processes:
#   Part 1 (presence):  is the site occupied at all?  (0/1, logistic)
#   Part 2 (abundance): given occupied, how many?     (positive, Gamma-log)

library(pscl)

# Part 1 — presence (uses ALL rows; zeros become the 0s)
model_df$present <- as.integer(model_df$prec_parr_ha > 0)     # added present col; 1 = the site had any parr, 0 = none
presence_model <- glm(present ~ Slope + TDA_km2 + Q95,        # glm() = generalized linear model
                      family = binomial, data = model_df)     # https://www.statology.org/interpret-glm-output-in-r/

# Part 2 — abundance (positives only; Gamma has no mass at zero)
positives <- subset(model_df, prec_parr_ha > 0)
density_model <- glm(prec_parr_ha ~ Slope + NLCD_42,
                     family = Gamma(link = "log"), data = positives)

summary(presence_model)
summary(density_model)
# ==============================================================================





# ==============================================================================
# 07. LASSO
# Penalized selection. Helper keeps every run self-contained: it filters to
# complete rows, drops zero-variance columns, standardizes, seeds the CV, and
# returns the fit + what it dropped + the sample size.

library(glmnet)

run_lasso <- function(vars, data = model_df, response = "log_prec_parr") {
  d    <- data[complete.cases(data[, c(response, vars)]), ]
  sds  <- sapply(d[, vars], sd, na.rm = TRUE)
  keep <- vars[is.finite(sds) & sds > 0]                 # drop constant cols
  y    <- d[[response]]
  x    <- as.matrix(as.data.frame(lapply(d[, keep], standardize)))
  set.seed(1)                                            # reproducible folds
  fit  <- cv.glmnet(x, y, alpha = 1)
  list(fit = fit, dropped = setdiff(vars, keep), n = nrow(d))
}

# reusable NLCD name vector
nlcd_all <- paste0("NLCD_", c(11,12,21,22,23,24,31,41,42,43,51,52,71,81,82,90,95))

# --- Model 1: ALL predictors (exploratory; contains collinear pairs) ----------
vars_all <- c("TDA_km2","MeanElev","Slope","Shape","Link","CLink","DLink",
              nlcd_all, "Q05","Q25","Q50","Q75","Q95","Mean")
model_1 <- run_lasso(vars_all)
plot(model_1$fit)                    # the actual fitted LASSO model (= cv.glmnet result)
coef(model_1$fit, s = "lambda.min")  # lambda.min = with the lowerst error (tends to slightly overfit)
coef(model_1$fit, s = "lambda.1se")  # lambda.1se = simplest model w/i 1 std. err. of that best (stronger penalty, fewer survivors)
model_1$dropped                      # the names of any predictors that got auto-removed for zero variance (constant columns).
model_1$n                            # how many rows the model was fit on (after dropping NAs)

# --- Model 2: one-from-each (DE-COLLINEARIZED — the clean, trustworthy one) ---
# note: proxies OR raw NLCD, not both; one temperature quantile only
vars_clean <- c("TDA_km2","Slope","Shape",
                "NLCD_42","NLCD_52","NLCD_71","NLCD_81","Q95")
model_2 <- run_lasso(vars_clean)
plot(model_2$fit)
coef(model_2$fit, s = "lambda.min")
coef(model_2$fit, s = "lambda.1se")
model_2$n

# --- Model 3: No rare NLCD, and sorted variables based on Model 1 result ------
nlcd_norm <- paste0("NLCD_", c(11,51,52,71,90))

vars_all <- c("MeanElev","Slope","Shape","Link",
              nlcd_norm, "Q05","Mean")

model_3 <- run_lasso(vars_all)
plot(model_3$fit)
coef(model_3$fit, s = "lambda.min")
coef(model_3$fit, s = "lambda.1se")
model_3$dropped; mA$n


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
# ==============================================================================




# ==============================================================================
# 08. ADULT:JACK RATIO 
library(ggplot2)
library(dplyr)
library(tidyr)

adult_jack_ratio <- read.csv(proj("explanatory", "adult_jack_ratio.csv"))


# --- line graph ---------------------------------------------------------------
x <- adult_jack_ratio$Year
y <- adult_jack_ratio$adult_jack

plot(x,y,type="l", col="black", lwd=2, main = "Annual Adult:Jack Ratio")


# --- stacked bar graph (side-by-side) -----------------------------------------
adult_jack_ratio_subset <- adult_jack_ratio %>%
  select(Year, spr_adult, spr_jack, su_adult, su_jack)
  

stackedbar <- adult_jack_ratio_subset %>%
  pivot_longer(cols = c("spr_adult", "spr_jack", "su_adult", "su_jack"), 
               names_to = "stage", values_to = "count")

ggplot(stackedbar, aes(x=Year, y=count, fill = stage)) + 
  geom_col() +
  labs(title = "Annual Counts of Life Stages by Year (Spring-Summer)") +
  xlab("Year") +
  ylab("Annual Counts (Spring-Summer") +
  theme_bw()


# --- percentage (standarized) + stacked bar + line graph ----------------------
# percentage
pct <- adult_jack_ratio %>%
  group_by(Year) %>%
  mutate(
    total = sum(spr_adult + spr_jack + su_adult + su_jack),
    pct_spr_adult = (spr_adult/total) * 100,
    pct_spr_jack = (spr_jack/total) * 100,
    pct_su_adult = (su_adult/total) * 100,
    pct_su_jack = (su_jack/total) * 100,
  )



# stacked bar
stackedbar <- pct %>%
  pivot_longer(cols = c("pct_spr_adult", "pct_spr_jack", "pct_su_adult", "pct_su_jack"), 
               names_to = "stage", values_to = "percentage")

ggplot(stackedbar, aes(x=Year, y=percentage, fill = stage)) + 
  geom_col() +
  labs(title = "Annual Ratio of Life Stages by Year (Spring-Summer)") +
  xlab("Year") +
  ylab("Annual Ratio (Spring-Summer") +
  theme_bw()



# line graph
ggplot(stackedbar, aes(x= Year, y = percentage, color = stage)) + 
  geom_line(linewidth = 1) +
  scale_color_manual(
    name = "Life Stage",
    values = c(
      "pct_spr_adult" = "blue",
      "pct_spr_jack" = "darkgreen",
      "pct_su_adult" = "orange",
      "pct_su_jack" = "red"
    ),
    labels = c(
      "pct_spr_adult" = "Spring Adult",
      "pct_spr_jack" = "Spring Jack",
      "pct_su_adult" = "Summer Adult",
      "pct_su_jack" = "Summer Jack"
    )
  ) +
  ylim(0,100) + 
  labs(
    title = "Annual Percentage of Life Stages by Year (Spring-Summer)",
    x = "Year",
    y = "Percentage"
  ) + 
  theme_bw() + 
  theme(plot.title = element_text(hjust = 0.5))
# ==============================================================================





# ==============================================================================
# 09. LANDCOVER
# landcover per site (average all site)

library(dplyr)

sites = colnames(landcover_data)

landcover_avg <- landcover_data %>%
  group_by(Ptagis_ID) %>%
  summarize(
    across(NLCD_11:last_col(), mean)
  )
# ==============================================================================





# ==============================================================================
# 10. FISH TAG
# (Tried API but due to lack of the API key, instead tried:)
# Pull year from the matching file_title from the metadata

fish_tag <- read.csv(proj("assembled", "idaho_wild_fish_tag_data_2026_06_24.csv"))

fish_tag <- fish_tag %>%
  left_join(meta_data %>% select(file_title, event_date, brood_year, migration_year),
            by = "file_title") %>%                         # because left_join matches rows by their values, I assigned it to match by file_title
  mutate(tag_year = format(as.Date(event_date), "%Y"))     # added the "tag_year" to fish_tag
# ==============================================================================





# ==============================================================================
# 11. HYPOTHESES (H1-H6)
# H1–H4: single/multi-predictor OLS on the log response, with diagnostics + a
# scatter. fit_report() cuts the repetition. H6: Mantel spatial test.

# helper: fit an lm, print summary + 4 diagnostic plots, draw a scatter
fit_report <- function(formula, xvar, title, color = "steelblue4") {
  m <- lm(formula, data = model_df)
  print(summary(m))
  op <- par(mfrow = c(2, 2)); plot(m); par(op)
  p <- ggplot(model_df, aes(x = .data[[xvar]], y = prec_parr_ha)) +
    geom_point(alpha = 0.6, color = color) +
    geom_smooth(method = "lm", color = "black", se = TRUE) +
    theme_minimal() +
    labs(title = title, x = xvar, y = "Wild Parr Density (fish/ha)")
  print(p)
  invisible(m)
}

# H1. WATERFLOW — density ~ slope (proxy for water speed)
flow_model <- fit_report(log_prec_parr ~ Slope, "Slope",
                         "H1: Waterflow speed (Slope) vs Parr Density", "purple")

# H2-2. CHANNEL CONFINEMENT — proxied by slope + drainage (no direct data)
confinement_model <- lm(log_prec_parr ~ scale(Slope) + scale(TDA_km2),
                        data = model_df)
summary(confinement_model)
op <- par(mfrow = c(2,2)); plot(confinement_model); par(op)

# H3-1. CANOPY — density ~ evergreen forest
forest_model <- fit_report(log_prec_parr ~ NLCD_42, "NLCD_42",
                           "H3-1: Evergreen Canopy vs Parr Density", "darkgreen")

# H3-2. FIRE — density ~ shrub + grassland (post-disturbance cover proxy)
model_df <- model_df %>% mutate(fire_proxy = NLCD_52 + NLCD_71)
fire_model <- fit_report(log_prec_parr ~ fire_proxy, "fire_proxy",
                         "H3-2: Post-Disturbance Cover vs Parr Density", "firebrick")

# H4. SEDIMENT & LWD — multiple regression
sediment_lwd_model <- lm(log_prec_parr ~ sediment_risk + lwd_proxy + Slope,
                         data = model_df)
summary(sediment_lwd_model)
op <- par(mfrow = c(2,2)); plot(sediment_lwd_model); par(op)

# H5. CHLOROPHYLL A — data-sourcing only, not yet modeled. See:
#   https://www.waterqualitydata.us/  (National Water Quality Monitoring Council)

# H6. RIVER DISTANCE — do sites close by river have similar densities?
site_density <- model_df %>%
  group_by(Ptagis_ID) %>%
  summarise(mean_log_parr = mean(log_prec_parr, na.rm = TRUE)) %>%
  ungroup() %>%
  slice(match(rownames(river_dmat), Ptagis_ID))     # match matrix order

density_dmat <- as.matrix(dist(site_density$mean_log_parr))
rownames(density_dmat) <- site_density$Ptagis_ID
colnames(density_dmat) <- site_density$Ptagis_ID

mantel_result <- mantel(as.dist(river_dmat), as.dist(density_dmat),
                        method = "pearson", permutations = 999)
mantel_result
# ==============================================================================





# ==============================================================================
# 12. EM Model
# Buidling Early Maturation Model using environmental and nutrient variables

# Select the sample site date (1. By location, 2. By (median) elevation)
# 1. By location
sample_upper   <- sites_map %>%
  filter(Ptagis_ID == "CAPEHC")

sample_middle  <- sites_map %>%
  filter(Ptagis_ID == "BEARVC")

sample_south   <- sites_map %>%
  filter(Ptagis_ID == "LAKEC")

sample_lower   <- sites_map %>%
  filter(Ptagis_ID == "CHAMBC")

  
# 2. By median elevation
# divide the median elevation by 5


#pick the middle row of each parts




# ==============================================================================
