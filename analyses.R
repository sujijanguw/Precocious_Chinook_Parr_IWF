

#===============================================================================
# DEFINITIONS
#===============================================================================

logadd <- function(x) {
# Function to figure out how much to add to a variable for log transformations
    10^floor(log10(min(x[x > 0], na.rm = TRUE)))
}



#===============================================================================
# ACQUISITIONS
#===============================================================================

# Libraries
    library(dplyr) # Data management
    library(glmnet) # LASSO regression models
    library(janitor) # Column renaming
    library(car) # qqPlots
    library(corrplot) # corrplots
    library(sf) # Spatial analyses
    library(plotrix) # All the fun things
    library(riverdist) # spatial autocorrelation analyses
    library(viridis) # whynot?
    library(vegan) # multivariate analyses

# Source R codes
    source("glmnetReplicate.R")

# Acquires parr densities
    parr_den <- read.csv("assembled/parr_density_ha.csv")
    
# Acquires various explanatory variables
    site_arch <- read.csv("explanatory/site_watershed_architecture.csv")
    stream_morph <- read.csv("explanatory/stream_morphology.csv")
    hydro <- read.csv("explanatory/hydro_data.csv")
    velocity <- read.csv("explanatory/velocity_estimates.csv")
    temps <- read.csv("explanatory/sample_modeled_temp_C.csv")
    lulc <- read.csv("explanatory/sample_lulc_proportions.csv")
    adults <- read.csv("explanatory/adult_jack_ratio.csv")
    
# Acquires the sample methods
    methods <- read.csv("meta/sample_methods.csv")
    methods <- na.omit(methods)
    
# Acquires the stream and site shapefiles
    streams <- st_read(dsn = "spatial", layer = "Salmon_streams_5070")
    sites <- st_read(dsn = "spatial", layer = "Sites_5070")
    

#===============================================================================
# MODEL DATA FRAME CREATION
#===============================================================================
    
# Calculates a temperature range metric
    temps$annual_range <- temps$Q95 - temps$Q05
    
# Sets the parr density year marker
    parr_den$Year <- parr_den$Cohort_Year
    
# Starts merging everything together
    parr_merge <- parr_den[, c("Ptagis_ID", "Year", "prec_parr_ha","cohort_parr_ha")] %>%
        left_join(site_arch[, c("Ptagis_ID", "Link", "Shape", "CLink")]) %>%
        left_join(stream_morph) %>%
        left_join(hydro[, c("Ptagis_ID", "Year", "median_annual_Q", "peak_date")]) %>%
        left_join(velocity) %>%
        left_join(temps[, c("Ptagis_ID", "Year", "Mean", "annual_range")]) %>%
        left_join(lulc[, c("Year", "Ptagis_ID", "NLCD_42", "NLCD_52", "NLCD_71")]) %>%
        left_join(adults[, c("Year", "adult_jack")]) %>%
        left_join(unique(methods)) %>% clean_names
        
# Removes samples which were not electrofishing only
    parr_merge <- parr_merge[parr_merge$method == "Shock", ]
    parr_merge <- parr_merge[, -ncol(parr_merge)]
    
# Fixes the temperature column name
    colnames(parr_merge) <- ifelse(colnames(parr_merge) == "mean", "mean_c",
        ifelse(colnames(parr_merge) == "annual_range", "annual_range_c",
            colnames(parr_merge)))
    
# Iterative look at variable distributions
    for (i in 3:ncol(parr_merge)) {
        
    # Checks for and creates directories
        if (!dir.exists("analyses")) {
            dir.create("analyses")
        }
        if(!dir.exists("analyses/distributions")) {
            dir.create("analyses/distributions")
        }
        
    # Assigns a file name
        file_name <- paste0("analyses/distributions/", i, "_",
            colnames(parr_merge)[i], "_distribution_check.png")
        
    # Extracts the variable
        var <- parr_merge[, i]
        
    # Figures out how much to add to log transform variables (avoids 0 values)
        log_add <- logadd(var)
        
    # Opens a png file for the plot
        png(file_name, width = 10, height = 5, units = "in", res = 200)
        
    # Sets the framing parameters
        par(mfrow = c(1, 2))
        par(mar = c(4.5, 4.5, 4.5, 0.5))
        
    # Plots the qqPlot for the raw variable
        qqPlot(var)
        mtext("Raw", side = 3, line = 0.5)
        
    # Plots the qqPlot for the transformed variable
        qqPlot(log10(var + log_add))
        mtext(expression(paste(Log["10"])), side = 3, line = 0.5)
        
    # Adds the variable title
        mtext(paste0(i, ": ", colnames(parr_merge)[i]), side = 3, line = -2, cex = 1.25,
            outer = TRUE)
        
    # Closes the figure
        dev.off()

    }


# Performs transformations based on these results
    parr_adj <- parr_merge
    log_cols <- c(3, 4, 5)
    for (i in log_cols) {
        parr_adj[, i] <- log10(parr_adj[, i] + logadd(parr_adj[, i]))
    }

# Removes missing values (for now)
    parr_adj_nona <- na.omit(parr_adj)
    
# Adjusts values to be standardized
    for (i in 3:ncol(parr_adj_nona)) {
        parr_adj_nona[, i] <- (parr_adj_nona[, i] - mean(parr_adj_nona[, i],
            na.rm = TRUE)) / sd(parr_adj_nona[, i], na.rm = TRUE)
    }
    
    
    
    
    
#===============================================================================
# GENERAL SPATIAL/TEMPORAL PATTERNS
#===============================================================================
    
# Creates the xy coordinates
# These are also used below in spatial autocorrelation analyses
    site_xy <- st_coordinates(sites)
    rownames(site_xy) <- sites$Ptagis_ID
    site_xy <- site_xy[rownames(site_xy) %in% parr_merge$ptagis_id, ]
    site_xy <- site_xy[order(rownames(site_xy)), ]
    
# Calculates mean precocious parr density among sites
    prec_parr_mean_ha <- tapply(parr_merge$prec_parr_ha,
        parr_merge$ptagis_id, mean, na.rm = TRUE)
    prec_parr_med_ha <- tapply(parr_merge$prec_parr_ha,
        parr_merge$ptagis_id, median, na.rm = TRUE)

# Opens a plot
    png("analyses/general_patterns.png", width = 6.5, height = 6.5,
        units = "in", res = 300)
    
# Sets framing parameters
    par(fig = c(0, 0.5, 0.5, 1), new = FALSE)
    par(mar = c(4.5, 4.5, 1, 1))
    
# Calculates the site ordering for the plot below
    site_ord <- order(prec_parr_med_ha)
    
# Plots the density by site
    boxplot(parr_merge$prec_parr_ha + 1 ~ reorder(parr_merge$ptagis_id,
        parr_merge$prec_parr_ha, median), boxwex = 0.4,
        staplewex = 0.2, pch = 20, main = "", xlab = "Site",
        ylab = "Precocious parr density (fish/ha)", axes = FALSE,
        cex.lab = 0.8, las = 2, col = adjustcolor("firebrick", alpha.f = 0.4),
        border = "firebrick", log = "y")
    
# Adds custom axes
    axis(side = 1, at = 1:15, labels = names(prec_parr_med_ha[site_ord]),
        las = 2, cex.axis = 0.6)
    axis(side = 2, at = c(1, 2, 3, 6, 11, 21), labels = c(0, 1, 2, 5, 10, 20),
        cex.axis = 0.8, las = 2)
    box()
    
# Plots the next figure: parr by year
    par(fig = c(0.5, 1, 0.5, 1), new = TRUE)

# Plots density by year
    boxplot(parr_merge$prec_parr_ha + 1 ~ factor(parr_merge$year,
        levels = 2000:2024), boxwex = 0.4, staplewex = 0.2, pch = 20,
        col = adjustcolor("firebrick", alpha.f = 0.4), border = "firebrick",
        axes = FALSE, cex.lab = 0.8, xlab = "Cohort year",
        ylab = "Precocious parr density (fish/ha)", log = "y")
    axis(side = 1, at = 1:25, labels = 2000:2024, las = 2, cex.axis = 0.6)
    axis(side = 2, at = c(1, 2, 3, 6, 11, 21), labels = c(0, 1, 2, 5, 10, 20),
        cex.axis = 0.8, las = 2)
    box()
        
# Third plot: Scaled mean abundance at a site
    par(fig = c(0.25, 0.75, 0, 0.5), new = TRUE)
    par(mar = c(1, 1, 1, 1))
    plot(st_geometry(streams), lwd = streams$StreamOrde/2, col = "grey60")
    
    
# Rescaling is done to remap 0-8 fish/ha to cex values of 0.5 to 4
    rescale_df <- data.frame(density = c(0, 8), cex = c(0.5, 4))
    rescale_mod <- lm(cex ~ density, data = rescale_df)
    pp_mha_rescale <- predict(rescale_mod,
        newdata = data.frame(density = prec_parr_mean_ha))
    
# Merges the rescaled values with the sites xy data
    site_xy_df <- data.frame(ptagis_id = rownames(site_xy), site_xy)
    site_xy_df <- right_join(site_xy_df,
        data.frame(ptagis_id = names(pp_mha_rescale), density = pp_mha_rescale))
    
# Plots the points
    points(site_xy_df$X, site_xy_df$Y, pch = 19, cex = site_xy_df$density,
        col = adjustcolor("firebrick", alpha.f = 0.4))
    
# Adds a kilometer bar
    init_xy <- c(-1428182, 2690757)
    rect(init_xy[1], init_xy[2], init_xy[1] + 10000, init_xy[2] + 5000,
        col = "black", border = "black", lwd = 0.5)
    rect(init_xy[1] + 10000, init_xy[2], init_xy[1] + 20000, init_xy[2] + 5000,
        col = "white", border = "black", lwd = 0.5)
    rect(init_xy[1] + 20000, init_xy[2], init_xy[1] + 30000, init_xy[2] + 5000,
        col = "black", border = "black", lwd = 0.5)
    rect(init_xy[1] + 30000, init_xy[2], init_xy[1] + 40000, init_xy[2] + 5000,
        col = "white", border = "black", lwd = 0.5)

    rect(init_xy[1] + 40000, init_xy[2], init_xy[1] + 50000, init_xy[2] + 5000,
        col = "black", border = "black", lwd = 0.5)
    
     
    text(init_xy[1] + 25000, init_xy[2] + 20000, "50km", cex = 0.8)
    

# Adds a legend
    par(fig = c(0.75, 1, 0, 0.5), new = TRUE)
    par(mar = rep(0, 4))
    plot(NULL, xlim = c(0, 1), ylim = c(0, 1), axes = FALSE, ann = FALSE)
    legend("left", legend = c("0", "2", "4", "8"),
        title = "Precocious\nparr density\n(fish/ha)",
        pch = 19, pt.cex = predict(rescale_mod,
            newdata = data.frame(density = c(0, 2, 4, 8))),
        col = adjustcolor("firebrick", alpha.f = 0.4),
        y.intersp = c(0.8, 1.2, 1.6, 2), x.intersp = c(1, 1.5, 2, 2.5),
        bty = "n", cex = 0.8)
    
# Closes the device
    dev.off()
    
    
    
#===============================================================================
# SPATIAL AUTOCORRELATION
#===============================================================================
    
# Creates a stream line object
 #   river_lines <- line2network(sf = streams)
  #  river_clean <- cleanup(river_lines)
  #  saveRDS(river_clean, "spatial/river_cleaned.rds")
    river_clean <- readRDS("spatial/river_cleaned.rds")
    

# Snaps sites to the river network
    site_snap <- xy2segvert(x = site_xy[, 1], y = site_xy[, 2],
        rivers = river_clean)
    
# Measures site pairwise distances
    site_dists <- riverdistancemat(seg = site_snap$seg, vert = site_snap$vert,
        rivers = river_clean)
    rownames(site_dists) <- colnames(site_dists) <- rownames(site_xy)
    site_dists <- as.dist(site_dists)
    
# Calculates difference in fish density between sites
    prec_parr_dist <- dist(prec_parr_mean_ha)
    
# Conducts Mantel test
    spatial_autocorrelation_mantel <- mantel(site_dists, prec_parr_dist,
        permutations = 10000)
    
# Plots results
    png("analyses/spatial_autocorrelation.png", width = 3.25, height = 3.25,
        units = "in", res =  300)
    par(mar = c(4.5, 6, 1, 1))
    plot(c(site_dists)/1000, c(prec_parr_dist),
        xlab = "Inter-site river distances (km)",
        ylab = "Difference in precocious\nparr density (fish/ha)",
        pch = 19, col = rgb(0, 0.7, 0.3, 0.25))
    dev.off()
    
    
    
#===============================================================================
# LASSO MODEL CONSTRUCTION
#===============================================================================
    
# Takes a look at the potential for collinearity / initial relationships
    png("analyses/parr_explan_corrplot.png", width = 7.5, height = 8,
        units = "in", res = 300)
    corrplot(cor(parr_adj_nona[, -c(1, 2)], use = "pairwise.complete.obs"))
    dev.off()
    
# Builds a tentative model set
    parr_mod_cv <- cv.glmnet(x = as.matrix(parr_adj_nona[, -c(1:3)]),
        y = parr_adj_nona[, 3])
    
# Takes a look at the optimal coefficients
    coef(parr_mod_cv, s = parr_mod_cv$lambda.min)
    
# Calculates the % deviance value
# This is roughly speaking analogous to an r2 value
    parr_mod_cv$glmnet.fit$dev.ratio[which(parr_mod_cv$glmnet.fit$lambda == parr_mod_cv$lambda.min)]

# Conducts the same thing 1000 times to get some ideas of parameter variability
    test_mods <- glmnetReplicate(parr_mod_cv)
    
# Saves a plot of parameter values
    png("analyses/model_coefficients.png", width = 6.5, height = 4.5, units = "in",
        res = 300)
    plot(test_mods)
    dev.off()
    
# Saves a plot of % deviance values
    png("analyses/percent_deviance.png", width = 6.5, height = 3.5, units = "in",
        res = 300)
    hist(test_mods$per_dev, breaks = seq(0, 1, by = 0.001), xlab = "% Deviance",
        ylab = "Frequency", main = "", border = NA, col = "black")
    dev.off()
    
    
    
    
    

  
# Saves various model outputs
    sink("analyses/model_outputs.txt")
    cat("Idaho Wild Spring/Summer Chinook Salmon Precocious Parr Analyses\n")
    cat("\n\nSpatial autocorrelation (Mantel's test):\n")
    print(spatial_autocorrelation_mantel)
    cat("\n\nLASSO Regression Model\n")
    print(test_mods)
    cat("\n\nAnalyses run on ")
    cat(as.character(Sys.Date()))
    cat("\n.")
    sink()
  
    
    
    
    
    