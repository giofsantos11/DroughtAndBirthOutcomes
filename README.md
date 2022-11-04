# DroughtAndBirthOutcomes

This repository contains the codes and the publicly available datasets used to prepare the analysis for a empirical research paper that investigates the effets of a drought on birth weights. 

<ins>The datasets include:</ins>
1. Child level data from the [Philippines National Demographic and Health Survey (NDHS) 2017](https://dhsprogram.com/publications/publication-fr347-dhs-final-reports.cfm). This data with the GIS variables can be requested from the [DHS Program](https://dhsprogram.com/) with the agreement that the data will be used for a specific purpose. For this reason, this repository does not contain these datasets and leave it to the replicators to request both thed cross-sectional survey data and cluster-level geographic data from the DHS team. 

2. 1°x1° grid cell data on a drought index called the Strandardized Precipitation Evapotranspiration Index [(SPEI)] downloaded from the [Global SPEI database](https://spei.csic.es/database.html). 

<ins>The codes include:</ins>
1. Spatial interpolation code file - this prepares the raster maps for the Philippines and interpolates the SPEI for the cluster locations in the Philippines NDHS 2017.

2. Data cleaning and preparation - trimming the dataset to include only relevant samples and columns, generating variables 

3. Preparing summary statistics (upcoming)

4. Runnning regressions (upcoming)
