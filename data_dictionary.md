# DATA DICTIONARY: Thirty years of juvenile Chinook salmon biometric data, with associated environmental and ecological covariates

\

## Contact information

#### Principle Investigator Contact Information

Name: Loren Stearman

Institution: NOAA Fisheries Northwest Fisheries Science Center

Email: Loren.Stearman@noaa.gov

#### Alternate Contact Information

Name: Jesse J. Lamb

Institution: NOAA Fisheries Northwest Fisheries Science Center

Email: Jesse.J.Lamb@noaa.gov

\

---

\

## Dataset Overview

### Dates of Data Collection

Data in this repository run from 1988 to 2025. Further updates are anticipated for newer data on an annual basis.

### Data Spatial Scope

Data in this repository cover the Salmon River watershed, including 16 collection localities

### Funding

This work was funded by a contract from Bonneville Power Administration (Contract #1991-028-00)

### Ethics Approval

All collection activities followed standard ethics protocols for NOAA Fisheries. 

### Sharing/Access Information

This work is licensed under a CC0 1.0 Universal (CC0 1.0) Public Domain Dedication license.

### Data Sources

Fish data from this project are derived from field collections of juvenile Spring-run Chinook Salmon from the Salmon River, Idaho, from 1988 to 2025. Land use/land cover data are derived from the National Land Cover Database (NLCD) Annual dataset, from 1992 to 2024. Modeled stream temperature data are derived from the the Pacific Northwest Predicted Stream Temperatures database, from 1992 to 2021. Stream architecture metrics are derived from the National Hydrography Dataset, V2. 

### Recommended Citation

Lamb, J. J., and L. W. Stearman. 2026. Thirty years of juvenile Chinook salmon biometric data, with associated environmental and ecological covariates. DOI: https://doi.org/10.5281/zenodo.20837314

### References (in this ReadMe)

Please list any references cited in this ReadMe document, or delete this subheading...

\

---

\

## Descriptions of the data and file structure

### File and folder descriptions

The folder "/assembled" contains data files derived from the raw tagging file assembly process. The folder "/explanatory" contains associated data which may be used in explanatory models. The folder "/meta" contains various metadata files. The folder "/spatial" contains associated geospatial files. 

#### assembled/idaho_wild_fish_tag_data_2026_06_24.csv

This file contains individual records of all fishes handled at the tagging stations during collection activities, including tag numbers, length and mass data, and various conditional comments. The records do include both tagged and untagged Chinook salmon. Bycatch data (but available on Zenodo at DOI: https://doi.org/10.5281/zenodo.17202532) were collected away from the station and not recorded here. 

#### assembled/parr_density_ha.csv

This file contains precocious parr density (fish/ha), and associated hatch year cohort density (fish/ha), derived from the file "assembled/idaho_wild_fish_tag_data_2026_06_24.csv".

#### explanatory/sample_lulc_proportions.csv

This file contains land use/land cover proportions for the upstream catchment of each sample site, annually. 

#### explanatory/sample_modeled_temp_C.csv

This file contains modeled temperature data for all sites. 

#### explanatory/site_watershed_architecture.csv

This file contains various watershed architecture metrics (stream size, C-link, etc). 

#### meta/idaho_wild_fish_metadata_2026_06_24.csv

This file is the core metadata file for the associated fish data file "assembled/idaho_wild_fish_tag_data_2026_06_24.csv". This file documents data such as locality and timing information.

#### meta/lulc_key.csv

This file provides a human-readable key to the land use/land cover numeric categories assigned by the NLCD.

#### meta/metadata_colname_key.csv

This file is a keyfile used in the data assembly process. Raw file type varied across years as techology improved, and this file helps the assembly script key across different file types. 

#### meta/sample_area_m2.csv

This file documents the total sample area (m^2) for each sample event. 

#### meta/site_key.csv

This file is a keyfile for use with different ways of referencing sites, including PTAGIS codes, human-readable site names, and an abbreviation system used in some associated publications. 

#### meta/sites.csv

This file documents the locations of the sample sites. 

#### spatial/Salmon_streams_5070.shp

This shapefile contains the geometry and associated attributes of the streams in the Salmon River watershed. 

#### spatial/Sites_5070.shp

This shapefile contains geometry and associated attributes derived from the file "meta/sites.csv".

\

### Methods

Samples were taken at 16 sites in the headwaters of the Salmon River, Idaho, from 1988 to 2025. Years 1998 - 1991 were pilot years, full project data begin in 1992. Fishes were collected using single-pass backpack electrofishing, retained in flow-through buckets, and tagged with passive integrated transponder (PIT) tags. At time of tagging, length, mass, and metrics of condition were measured for each individual. Fishes smaller than 55mm were not tagged, but covariate data were still collected. Data are formatted to be generally consistent with data from the Columbia Basin PIT Tag Information System (PTAGIS, https://www.ptagis.org). 

Land cover, temperature, and watershed architecture metrics were extracted from their respective data sources to match sample site locations (see specific methods below). 

\

#### assembled/idaho_wild_fish_tag_data_2026_06_24.csv

Raw tagging files (typically representing one day of tagging and not contained in this repository) varied in format over years as technology improved. The compiled file was created via an analytical pipeline which assembled files, matching data types, and creating one standardized format. Sample-level metadata were removed from this file and are contained in the file "/meta/idaho_wild_fish_metadata_2026_06_24.csv", also in this repository. 

#### assembled/parr_density_ha.csv

Please add a specific description of the methods used to generate this file...

#### explanatory/sample_lulc_proportions.csv

Please add a specific description of the methods used to generate this file...

#### explanatory/sample_modeled_temp_C.csv

Please add a specific description of the methods used to generate this file...

#### explanatory/site_watershed_architecture.csv

Please add a specific description of the methods used to generate this file...

#### meta/idaho_wild_fish_metadata_2026_06_24.csv

Please add a specific description of the methods used to generate this file...

#### meta/lulc_key.csv

Please add a specific description of the methods used to generate this file...

#### meta/metadata_colname_key.csv

Please add a specific description of the methods used to generate this file...

#### meta/sample_area_m2.csv

Please add a specific description of the methods used to generate this file...

#### meta/site_key.csv

Please add a specific description of the methods used to generate this file...

#### meta/sites.csv

Please add a specific description of the methods used to generate this file...

#### spatial/Salmon_streams_5070.shp

Please add a specific description of the methods used to generate this file...

#### spatial/Sites_5070.shp

Please add a specific description of the methods used to generate this file...

\

### File Structure

*A note on sample file structure*: Unless otherwise indicated, "year" refers to the year a sample was taken. 

#### assembled/idaho_wild_fish_tag_data_2026_06_24.csv

Number of header rows: 1

Number of footer rows: 0

Number of variables: 9

Number of data rows: 419980

Variable list:


- file_title (character): The file title associated with the record (matches file_title in the metadata file)
- record# (integer): The record number associated with the record
- event_type (logical): The type of sampling event (mark, tally, etc). These data were not recorded in early years. 
- pit_tag (character): The PIT tag code of a PIT tag injected into the fish. A value of .......... indicates no tag.
- length (integer): The fork length in mm of the fish.
- weight (numeric): The mass in grams of the fish.
- srr_code (character): The species, run, and rearing code of the fish.
- conditional_comments (character): Standardized comments regarding the record. 
- text_comments (character): Nonstandard or unique comments regarding the record. 

Data type(s): character, integer, logical, numeric

Missing data value: NA

Comments: Data comply with PTAGIS standards. See PTAGIS for detailed descriptions of srr codes and conditional comments. 

\

#### assembled/parr_density_ha.csv

Number of header rows: 1

Number of footer rows: 0

Number of variables: 5

Number of data rows: 255

Variable list:


- Ptagis_ID (character): The site ID using the PTAGIS code.
- Cohort_Year (integer): The year that the precocious fish hatched. 
- Sample_Year (integer): The year that the precocious fish were sampled. 
- cohort_parr_ha (numeric): The total parr density (fish/ha) observed in the cohort year, not sample year, for the precocious fish.
- prec_parr_ha (numeric): The precocious parr density in the sample year (fish/ha). 

Data type(s): character, integer, numeric

Missing data value: NA



\

#### explanatory/sample_lulc_proportions.csv

Number of header rows: 1

Number of footer rows: 0

Number of variables: 19

Number of data rows: 388

Variable list:


- Ptagis_ID (character): The site ID using PTAGIS codes. 
- Year (integer): The sample year.
- NLCD_11 (numeric): The proportion of the upstream catchment containing open water. 
- NLCD_12 (numeric): The proportion of the upstream catchment containing perrennial ice/snow
- NLCD_21 (numeric): The proportion of the upstream catchment containing developed, open space
- NLCD_22 (numeric): The proportion of the upstream catchment containing developed, low intensity
- NLCD_23 (numeric): The proportion of the upstream catchment containing developed medium intensity
- NLCD_24 (numeric): The proportion of the upstream catchment containing developed, high intensity
- NLCD_31 (numeric): The proportion of the upstream catchment containing barren land (rock/sand/clay)
- NLCD_41 (numeric): The proportion of the upstream catchment containing deciduous forest
- NLCD_42 (numeric): The proportion of the upstream catchment containing evergreen forest
- NLCD_43 (numeric): The proportion of the upstream catchment containing mixed forest
- NLCD_51 (integer): The proportion of the upstream catchment containing dwarf scrub
- NLCD_52 (numeric): The proportion of the upstream catchment containing dwarf shrub
- NLCD_71 (numeric): The proportion of the upstream catchment containing grassland/herbaceous
- NLCD_81 (numeric): The proportion of the upstream catchment containing pasture/hay
- NLCD_82 (numeric): The proportion of the upstream catchment containing cultivated crops
- NLCD_90 (numeric): The proportion of the upstream catchment containing woody wetlands
- NLCD_95 (numeric): The proportion of the upstream catchment containing emergent herbaceous wetlands

Data type(s): character, integer, numeric

Missing data value: NA



\

#### explanatory/sample_modeled_temp_C.csv

Number of header rows: 1

Number of footer rows: 0

Number of variables: 8

Number of data rows: 594

Variable list:


- Ptagis_ID (character): The site ID using PTAGIS codes.
- Year (integer): The sample year.
- Q05 (numeric): The 5th quartile of mean annual daily temperatures
- Q25 (numeric): The 25th quartile of mean annual daily temperatures
- Q50 (numeric): The 50th quartile of mean annual daily temperatures
- Q75 (numeric): The 75th quartile of mean annual daily temperatures 
- Q95 (numeric): The 95th quartile of mean annual daily temperatures 
- Mean (numeric): The mean of mean (grand mean) annual daily temperatures

Data type(s): character, integer, numeric

Missing data value: NA



\

#### explanatory/site_watershed_architecture.csv

Number of header rows: 1

Number of footer rows: 0

Number of variables: 8

Number of data rows: 18

Variable list:


- Ptagis_ID (character): The site ID using PTAGIS codes. 
- TDA_km2 (numeric): The total drainage area in km^2.
- MeanElev (numeric): The mean elevation (m).
- Slope (numeric): The slope for the stream reach containing the site (m/m). 
- Shape (numeric): The shape metric (ranges 0 - 1, 0 = long, 1 = round) for the upstream watershed.
- Link (integer): The link magnitude (number of 1st order stream tributaries) of the site. 
- CLink (integer): The C-link magnitude (number of segments downstream) to the base of the Salmon River for the site. 
- DLink (integer): The D-link magnitude (link magnitude of the next downstream segment) of the site. 

Data type(s): character, integer, numeric

Missing data value: NA



\

#### meta/idaho_wild_fish_metadata_2026_06_24.csv

Number of header rows: 1

Number of footer rows: 0

Number of variables: 30

Number of data rows: 1376

Variable list:


- session (character): An alphanumeric code designating the unique tagging incident (not recorded in earlier years).
- project_code (character): A 2-3 character abbreviation of the assigned project code for PTAGIS, SA: Steve Achord, GAA: Gordon Axel. 
- session_message (character): Basic comments on the sampling/tagging event.
- session_note (character): Additional comments on the sampling/tagging event. 
- event_date (character): The event date/time.
- event_date_.pst. (character): The event date/time in PST.
- event_site (character): The site where sampling occurred, using long-form site names.  
- life_stage (character): The developmental stage of the fish at the event
- brood_year (integer): The year the adult parents spawned and fertilized the eggs.
- migration_year (integer): The expected year for the fish to migrate to the ocean.
- spawn_year (logical): 
- release_site (character): The site where the fish as released, using long-form site names.  
- release_temp (numeric): Water temperature (°C) recorded at the time of release.
- release_date (character): The date and time the fish was released.
- release_date_.pst. (character): The release date in PST.
- tagger (character): Name of the individual who tagged the fish, formats varied.
- organization (character): The organization conducting the tagging.
- capture_method (character): Method used to capture the fish.
- mark_method (character): Method used to apply the tag. (AUTO = automated tagging, HAND = hand-tagging)
- mark_temp (numeric): Water temperature (°C) recorded at the time of marking/tagging.
- hold_temp (numeric): Water temperature (°C) at which fish were held prior to release.
- file_title (character): Source data file identifier for the tagging record.
- release_river_km (character): Please write a short description of this variable (522.303.319.151.5, 522.303.319.151.5, ...) 
- species (integer): Species code from the SRR system.
- hatchery_site (logical): Whether the fish originated from a hatchery site.
- run (integer): Run-timing code from the SRR system 
- stock (logical): Genetic/broodstock origin. 
- rearing_type (character): Rearing origin from the SRR code (W = wild)
- raceway.transect (logical): Raceway (hatchery holding channel) or transect (standardized survey line) identifier tracking specimen origin.
- close_date (character): The date and time the tagging session/event was closed.

Data type(s): character, integer, logical, numeric

Missing data value: NA



\

#### meta/lulc_key.csv

Number of header rows: 8

Number of footer rows: 5

Number of variables: 2

Number of data rows: 5

Variable list:


- V1 (character): Please write a short description of this variable (41,Deciduous, 42,Evergreen, ...) 
- V2 (character): Please write a short description of this variable (Forest, Forest, ...)

Data type(s): character

Missing data value: NA



\

#### meta/metadata_colname_key.csv

Number of header rows: 20

Number of footer rows: 0

Number of variables: 3

Number of data rows: 6

Variable list:


- V1 (character): Please write a short description of this variable (COORDINATOR, RELEASE, ...) 
- V2 (character): Please write a short description of this variable (ID,PROJECT, DATE,RELEASE, ...) 
- V3 (character): Please write a short description of this variable (CODE, DATE, ...)

Data type(s): character

Missing data value: NA



\

#### meta/sample_area_m2.csv

Number of header rows: 0

Number of footer rows: 6

Number of variables: 19

Number of data rows: 28

Variable list:


- year (integer): Please write a short description of this variable (1992, 1993, ...) 
- BEARVC (integer): Please write a short description of this variable (38993, 58490, ...) 
- BIG2C (integer): Please write a short description of this variable (43652, 43652, ...) 
- BIGC (integer): Please write a short description of this variable (30000, 50000, ...) 
- CAMASC (integer): Please write a short description of this variable (24000, 32000, ...) 
- CAPEHC (integer): Please write a short description of this variable (5355, NA, ...) 
- CHAMBC (integer): Please write a short description of this variable (NA, NA, ...) 
- CHAMWF (integer): Please write a short description of this variable (920, 920, ...) 
- ELKC (integer): Please write a short description of this variable (30707, 40943, ...) 
- HERDC (integer): Please write a short description of this variable (15678, 26130, ...) 
- LAKEC (integer): Please write a short description of this variable (59037, 59037, ...) 
- LOONC (integer): Please write a short description of this variable (20000, 30000, ...) 
- MARSHC (integer): Please write a short description of this variable (32130, 32130, ...) 
- RUSHC (integer): Please write a short description of this variable (NA, NA, ...) 
- SALREF (integer): Please write a short description of this variable (56000, 56000, ...) 
- SALRSF (integer): Please write a short description of this variable (64320, 64320, ...) 
- SECESR (integer): Please write a short description of this variable (84542, 84542, ...) 
- SULFUC (integer): Please write a short description of this variable (38556, NA, ...) 
- VALEYC (integer): Please write a short description of this variable (42274, 84548, ...)

Data type(s): integer

Missing data value: NA



\

#### meta/site_key.csv

Number of header rows: 0

Number of footer rows: 0

Number of variables: 4

Number of data rows: 33

Variable list:


- V1 (character): Please write a short description of this variable (Old, BEAR VALLEY, ...) 
- V2 (character): Please write a short description of this variable (Official_ID, Bear Valley Creek, ...) 
- V3 (character): Please write a short description of this variable (Ptagis_ID, BEARVC, ...) 
- V4 (character): Please write a short description of this variable (Short_ID, BV, ...)

Data type(s): character

Missing data value: NA



\

#### meta/sites.csv

Number of header rows: 0

Number of footer rows: 0

Number of variables: 7

Number of data rows: 16

Variable list:


- Name (character): Please write a short description of this variable (Bear Valley Creek, Big Creek (lower), ...) 
- Ptagis_ID (character): Please write a short description of this variable (BEARVC, BIG2C, ...) 
- Lat_NAD83 (numeric): Please write a short description of this variable (44.42759, 45.10339, ...) 
- Lon_NAD83 (numeric): Please write a short description of this variable (-115.33068, -114.85398, ...) 
- COMID (integer): Please write a short description of this variable (23519305, 23531915, ...) 
- Lat_m (numeric): Please write a short description of this variable (2537574.676, 2603786.066, ...) 
- Lon_m (numeric): Please write a short description of this variable (-1524559.92, -1472635.03, ...)

Data type(s): character, integer, numeric

Missing data value: NA



\

#### spatial/Salmon_streams_5070.shp

Geometry Type(s): LINESTRING

Coordinate System Type: Planar

CRS: NAD_1983_Albers

EPSG: NA

Units: metre

Extent: xmin -1603748.0714, ymin 2464144.6243, xmax -1349182.4775, ymax 2744447.3106

Number of variables: 55

Number of rows: 3690

Variable list:


- COMID (numeric): Please write a short description of this variable (23479329, 23479331, ...) 
- FDATE (Date): Please write a short description of this variable (2001-01-25, 2001-01-25, ...) 
- RESOLUTION (character): Please write a short description of this variable (Medium, Medium, ...) 
- GNIS_ID (character): Please write a short description of this variable (381981, 381981, ...) 
- GNIS_NAME (character): Please write a short description of this variable (Fourth Of July Creek, Fourth Of July Creek, ...) 
- LENGTHKM (numeric): Please write a short description of this variable (1.245, 1.756, ...) 
- REACHCODE (character): Please write a short description of this variable (17060201000579, 17060201000580, ...) 
- FLOWDIR (character): Please write a short description of this variable (With Digitized, With Digitized, ...) 
- FTYPE (character): Please write a short description of this variable (StreamRiver, StreamRiver, ...) 
- FCODE (numeric): Please write a short description of this variable (46006, 46006, ...) 
- AreaSqKM (numeric): Please write a short description of this variable (1.5273, 2.4039, ...) 
- TotDASqKM (numeric): Please write a short description of this variable (37.8612, 33.3396, ...) 
- DUP_COMID (numeric): Please write a short description of this variable (0, 0, ...) 
- DUP_ArSqKM (numeric): Please write a short description of this variable (0, 0, ...) 
- DUP_Length (numeric): Please write a short description of this variable (1.245, 1.756, ...) 
- OID_ (numeric): Please write a short description of this variable (0, 0, ...) 
- ComID_1 (numeric): Please write a short description of this variable (23479329, 23479331, ...) 
- Fdate_1 (Date): Please write a short description of this variable (2012-07-02, 2012-07-02, ...) 
- StreamLeve (integer): Please write a short description of this variable (6, 6, ...) 
- StreamOrde (integer): Please write a short description of this variable (3, 3, ...) 
- StreamCalc (integer): Please write a short description of this variable (3, 3, ...) 
- FromNode (numeric): Please write a short description of this variable (50049557, 50049558, ...) 
- ToNode (numeric): Please write a short description of this variable (50049556, 50049557, ...) 
- Hydroseq (numeric): Please write a short description of this variable (50054028, 50057988, ...) 
- LevelPathI (numeric): Please write a short description of this variable (50045297, 50045297, ...) 
- Pathlength (numeric): Please write a short description of this variable (1465.758, 1467.003, ...) 
- TerminalPa (numeric): Please write a short description of this variable (50001315, 50001315, ...) 
- ArbolateSu (numeric): Please write a short description of this variable (30.084, 24.54, ...) 
- Divergence (integer): Please write a short description of this variable (0, 0, ...) 
- StartFlag (integer): Please write a short description of this variable (0, 0, ...) 
- TerminalFl (integer): Please write a short description of this variable (0, 0, ...) 
- DnLevel (integer): Please write a short description of this variable (6, 6, ...) 
- ThinnerCod (integer): Please write a short description of this variable (0, 0, ...) 
- UpLevelPat (numeric): Please write a short description of this variable (50045297, 50045297, ...) 
- UpHydroseq (numeric): Please write a short description of this variable (50057988, 50062762, ...) 
- DnLevelPat (numeric): Please write a short description of this variable (50045297, 50045297, ...) 
- DnMinorHyd (numeric): Please write a short description of this variable (0, 0, ...) 
- DnDrainCou (integer): Please write a short description of this variable (1, 1, ...) 
- DnHydroseq (numeric): Please write a short description of this variable (50050664, 50054028, ...) 
- FromMeas (numeric): Please write a short description of this variable (0, 0, ...) 
- ToMeas (numeric): Please write a short description of this variable (100, 100, ...) 
- ReachCod_1 (character): Please write a short description of this variable (17060201000579, 17060201000580, ...) 
- LengthKM_1 (numeric): Please write a short description of this variable (1.245, 1.756, ...) 
- Fcode_1 (numeric): Please write a short description of this variable (46006, 46006, ...) 
- RtnDiv (integer): Please write a short description of this variable (0, 0, ...) 
- OutDiv (integer): Please write a short description of this variable (0, 0, ...) 
- DivEffect (integer): Please write a short description of this variable (0, 0, ...) 
- VPUIn (integer): Please write a short description of this variable (0, 0, ...) 
- VPUOut (integer): Please write a short description of this variable (0, 0, ...) 
- TravTime (numeric): Please write a short description of this variable (0, 0, ...) 
- PathTime (numeric): Please write a short description of this variable (0, 0, ...) 
- AreaSqKM_1 (numeric): Please write a short description of this variable (1.5273, 2.4039, ...) 
- TotDASqK_1 (numeric): Please write a short description of this variable (37.8612, 33.3396, ...) 
- DivDASqKM (numeric): Please write a short description of this variable (37.8612, 33.3396, ...) 
- Dam50m (integer): Please write a short description of this variable (0, 0, ...)

Data type(s): character, Date, integer, numeric

Missing data value: NA

Associated File Types: cpg, dbf, prj, sbn, sbx, shx, xml



\

#### spatial/Sites_5070.shp

Geometry Type(s): POINT

Coordinate System Type: Planar

CRS: NAD83 / Conus Albers

EPSG: 5070

Units: metre

Extent: xmin -1550346.90710781, ymin 2490562.65756346, xmax -1449548.25402898, ymax 2640187.34145005

Number of variables: 7

Number of rows: 16

Variable list:


- Name (character): Please write a short description of this variable (Bear Valley Creek, Big Creek (lower), ...) 
- Ptagis_ID (character): Please write a short description of this variable (BEARVC, BIG2C, ...) 
- Lat_NAD83 (numeric): Please write a short description of this variable (44.42759, 45.10339, ...) 
- Lon_NAD83 (numeric): Please write a short description of this variable (-115.33068, -114.85398, ...) 
- COMID (numeric): Please write a short description of this variable (23519305, 23531915, ...) 
- Lat_m (numeric): Please write a short description of this variable (2537574.676, 2603786.066, ...) 
- Lon_m (numeric): Please write a short description of this variable (-1524559.92, -1472635.03, ...)

Data type(s): character, numeric

Missing data value: NA

Associated File Types: cpg, dbf, prj, qmd, shx







---
(STILL NEED TO RUN THE SOFTWARE!!)

#### WATER.csv
- Strm_code (character): The stream code identifying the sampling stream. Codes:
  MAR = Marsh, BEN = Bench Creek, BEV = Bever Creek, BVA = Bear Valley,
  CAM = Camas, CAP = Cape Horn, CHA = Chamberlain, CHO = Cape Horn,
  CUR = Curtis, ELK = Elk Creek, ETR = Elk Creek Tributary to Valley,
  GER = Germania, IRO = Iron Creek, KEN = Kennally Creek, LAK = Lake Creek,
  LBG = Lower Big, LOL = Lola Creek, LOO = Loon, MEA = Meadow,
  RLC = Redfish Lake Creek, RUS = Rush, SEC = Secesh, SFS = South Fork,
  SLC = Stanley Lake Creek, SUL = Sulphur, SUM = Summit Creek, TRA = Trap Creek,
  UBG = Upper Big Creek, UBS = Upper Big (a different site), VAL = Valley Creek,
  WFC = West Fork Chamberlain. [VAC, VAM unresolved]
- Reach (integer): The reach number within the stream.
- Reason (character): The reason/campaign the sample was collected under (e.g. "Sept Blitz").
- Date_coll (character): The date the sample was collected.
- Site (integer): The site number.
- Nut_bott (integer): The bottle ID for the nutrient sample.
- Tntp_bott (integer): The bottle ID for the total nitrogen / total phosphorus sample.
- Tb_fil (character): The filter ID used for the turbidity/suspended-solids measurement.
- Tb_vol_fil (numeric): The volume of water filtered.
- Tb_ini_filwt (numeric): The initial (pre-filtration) filter weight in grams.
- Tb_dry_filwt (numeric): The filter weight after drying, in grams.
- Tb_ash_filwt (numeric): The filter weight after ashing (combustion), in grams.
- Turb_note (character): Notes on the turbidity/filtration measurement.
- Po4_p (numeric): The phosphate concentration, measured as phosphorus (PO4-P).
- Sio4_si (numeric): The silicate concentration, measured as silicon (SiO4-Si).
- No3_n (numeric): The nitrate concentration, measured as nitrogen (NO3-N).
- No2_n (numeric): The nitrite concentration, measured as nitrogen (NO2-N).
- Nh4_n (numeric): The ammonium concentration, measured as nitrogen (NH4-N).
- Nut_note (character): Notes on the nutrient measurement.
- Tp (numeric): The total phosphorus concentration.
- Tn (numeric): The total nitrogen concentration.
- Tntp_note (character): Notes on the total nitrogen / total phosphorus measurement.
- Nut_seqno (integer): The sequence number for the nutrient sample.
- Nut_df (numeric): The dilution factor applied to the nutrient sample.
- Nut_uwfile (character): The source UW (University of Washington) lab file for the nutrient data.
- Tntp_seqno (integer): The sequence number for the TN/TP sample.
- Tntp_df (numeric): The dilution factor applied to the TN/TP sample.
- Tntp_uwfile (character): The source UW lab file for the TN/TP data.
- Doc (numeric): The dissolved organic carbon concentration.
- Doc_bott (integer): The bottle ID for the dissolved organic carbon sample.
- Doc_a (numeric): The average dissolved organic carbon value across replicate measurements.
- Doc_sd (numeric): The standard deviation of the replicate DOC measurements.
- Doc_cv (numeric): The coefficient of variation of the replicate DOC measurements.
- Doc_mol (numeric): The dissolved organic carbon concentration in molar units.
- Doc_note (character): Notes on the dissolved organic carbon measurement.
- Doc_uwfile (character): The source UW lab file for the DOC data.
- Fld_note (character): Field notes recorded at the time of collection.
- Entered_by (character): The person who entered the record.
- Entered_on (character): The date the record was entered.
- Po4_p (numeric): The phosphate concentration, measured as phosphorus (PO4-P).
- Sio4_si (numeric): The silica concentration, measured as silicon (SiO4-Si).
- No3_n (numeric): The nitrate concentration, measured as nitrogen (NO3-N).
- No2_n (numeric): The nitrite concentration, measured as nitrogen (NO2-N).
- Nh4_n (numeric): The ammonium concentration, measured as nitrogen (NH4-N).
- Tp (numeric): The total phosphorus concentration (Total P).
- Tn (numeric): The total nitrogen concentration (Total N).
- - Record_last_edited_by_user (character): The user who last edited the record.
- Record_last_edited_on_date (character): The date the record was last edited.

---




\

\

---

\

## Associated Code or Software

There are no code or software files associated with this repository.


This ReadMe was generated on 2026-06-25.
