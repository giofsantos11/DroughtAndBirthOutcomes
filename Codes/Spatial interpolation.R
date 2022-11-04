#-------------------------------------
# Interpolate spatial data
# Angelo Santos
# Version control:
  # November 1, 2022  -- instead of creating grid maps, interpolate the points directly
  #                   -- intersecting the raster map with the point data is problematic
  #                   because points on the grid cell are not assigned any values
#------------------------------------
# Clear memory
rm(list=ls())   

# Load the packages
library(tidyverse)
library(dplyr)
library(purrr)
library(raster)
library(sf)
library(tidyverse)
library(tmap)
library(skimr)
library(viridis)
library(haven)
library(data.table)
library(gstat) # Use gstat's idw routine
library(sp)    # Used for the spsample function
library(sfheaders)
# Step 1: Combine the grid cell data. Each cvs file represents a vertex
#         where data is available for SPEI from 1 to 48 month time scale for all months
#         between 1950 and Sept 2022

# Locate the folder containing the grid data csv files
path <- "/Users/angelosantos/Library/CloudStorage/OneDrive-GeorgeMasonUniversity-O365Production/PUBP 833/Datasets/Grid data/new"
maps <- "/Users/angelosantos/Library/CloudStorage/OneDrive-GeorgeMasonUniversity-O365Production/PUBP 833/Documentation/Maps"
# Create a list of files stored in the path
files <- list.files(path=path, full.names = TRUE)

# Append all the csv files
file_list <- list()
file_list <- lapply(files, function(x){
  ret <- read_csv(x)
  ret$origin <- x
  return(ret)})

df <- rbindlist(file_list)

# Step 2: Prepare the spatial data 
#         a. Create columns for year and latlong coordinates
#         b. Create trimmed data frames for each year so we can make raster maps per year
#         c. Take mean SPEI for each vertex

# Extract year information from the month variable
df$year <- as.numeric(substr(df$DATA, 4, 8))

# Extract the latitude and longitude from the file name
df$lat <- as.numeric(str_sub(df$origin, -16, -12))
df$lat2 <- as.numeric(str_sub(df$origin, -15, -12))
df$lat2

df <-  df %>%
  mutate(lat = ifelse(is.na(lat) , lat2, lat))
summary(df$lat)

df$long <- as.numeric(str_sub(df$origin, -10, -5))
summary(df$long)

# Set data column as a date
df$DATA <- as.Date(paste(df$DATA, '01'), '%B %Y %d')

# Create dataframes for each year, trim it to include only 6-, 12- and 18-month time frames

  for(i in 2012:2016) {
    assign(paste0("spatialdata_", i, "_sp"), 
    as(assign(paste0("spatialdata_", i), st_as_sf(df %>% filter (year == i)  %>% 
             group_by(lat,long) %>%
             summarize(mean_s6 = mean(SPEI_6),
                       mean_s12 = mean(SPEI_12),
                       mean_s18 = mean(SPEI_18)), coords = c("long", "lat"), crs = 4326)),
              Class = "Spatial"))
    }

# Step 3: Inerpolate the data
#         a. Load the Philippines shape file
#         b. Create trimmed data frames for each year so we can make raster maps per year
#         c. Load the NDHS dataset with the cluster location

# Load Philippine shape file
provborders <- st_read("/Users/angelosantos/Library/CloudStorage/OneDrive-GeorgeMasonUniversity-O365Production/PUBP 833/Datasets/Grid data/gadm36_PHL_shp/gadm36_PHL_0.shp")

# Transfrom from sf to sp
provborders_sp = as(provborders, Class = "Spatial")
grd   <- as.data.frame(spsample(provborders_sp, "regular", n= 2500))
plot(grd)

# change the variable names of grd
names(grd)       <- c("X", "Y")
# tell R that those variable names correspond to coordinates
coordinates(grd) <- c("X", "Y")
# change the lattice of points into a grid
# Create SpatialPixel object. SpatialPixels stores the x and y coordinates 
# for each pixel, unless the pixel value is NA.
gridded(grd)     <- TRUE
# Create SpatialGrid object. SpatialGrid objects store the grid geometry in a
# GridTopology class which is a few numbers defining the grid size
# and dimensions.
fullgrid(grd)    <- TRUE  

# Add modern_borders_clip_sp projection information to the empty grid
proj4string(grd) <- proj4string(provborders_sp)
# now it's spatial
crs(grd)

idp = 5

# Create raster map for each year

spei12_idw_2012 <- gstat::idw(mean_s12 ~ 1, spatialdata_2012_sp,
                              newdata=grd, idp=idp)
spei12_idw_2013 <- gstat::idw(mean_s12 ~ 1, spatialdata_2013_sp,
                              newdata=grd, idp=idp)
spei12_idw_2014 <- gstat::idw(mean_s12 ~ 1, spatialdata_2014_sp,
                              newdata=grd, idp=idp)
spei12_idw_2015 <- gstat::idw(mean_s12 ~ 1, spatialdata_2015_sp,
                              newdata=grd, idp=idp)
spei12_idw_2016 <- gstat::idw(mean_s12 ~ 1, spatialdata_2016_sp,
                              newdata=grd, idp=idp)

# Convert to raster object then mask
spei12_2012_raster       <- raster(spei12_idw_2012)
spei12_2012_raster_clip     <- mask(spei12_2012_raster, provborders_sp)

spei12_2013_raster       <- raster(spei12_idw_2013)
spei12_2013_raster_clip     <- mask(spei12_2013_raster, provborders_sp)

spei12_2014_raster       <- raster(spei12_idw_2014)
spei12_2014_raster_clip     <- mask(spei12_2014_raster, provborders_sp)

spei12_2015_raster       <- raster(spei12_idw_2015)
spei12_2015_raster_clip     <- mask(spei12_2015_raster, provborders_sp)

spei12_2016_raster       <- raster(spei12_idw_2016)
spei12_2016_raster_clip     <- mask(spei12_2016_raster, provborders_sp)


# Plot
raster2012 <- tm_shape(spei12_2012_raster_clip) + 
  tm_raster(n=7,palette = c("#d7191c", "#fdae61", "#ffffbf", "#abd9e9", "#2c7bb6"), 
            title="Drought index", breaks = c(-10, -2, -1.5, -1, 1, 1.5, 2, 10)) + 
  tm_shape(provborders_sp) + tm_dots(NA) +
  tm_legend(legend.outside=FALSE, legend.position = c("left", "center"))

raster2013 <- tm_shape(spei12_2013_raster_clip) + 
  tm_raster(n=7,palette = c("#d7191c", "#fdae61", "#ffffbf", "#abd9e9", "#2c7bb6"), 
            title="Drought index", breaks = c(-10, -2, -1.5, -1, 1, 1.5, 2, 10)) + 
  tm_shape(provborders_sp) + tm_dots(NA) +
  tm_legend(legend.outside=FALSE, legend.position = c("left", "center"))

raster2014 <- tm_shape(spei12_2014_raster_clip) + 
  tm_raster(n=7,palette = c("#d7191c", "#fdae61", "#ffffbf", "#abd9e9", "#2c7bb6"), 
            title="Drought index", breaks = c(-10, -2, -1.5, -1, 1, 1.5, 2, 10)) + 
  tm_shape(provborders_sp) + tm_dots(NA) +
  tm_legend(legend.outside=FALSE, legend.position = c("left", "center"))

raster2015 <- tm_shape(spei12_2015_raster_clip) + 
  tm_raster(n=7,palette = c("#d7191c", "#fdae61", "#ffffbf", "#abd9e9", "#2c7bb6"), 
            title="Drought index", breaks = c(-10, -2, -1.5, -1, 1, 1.5, 2, 10)) + 
  tm_shape(provborders_sp) + tm_dots(NA) +
  tm_legend(legend.outside=FALSE, legend.position = c("left", "center"))

raster2016 <- tm_shape(spei12_2016_raster_clip) + 
  tm_raster(n=7,palette = c("#d7191c", "#fdae61", "#ffffbf", "#abd9e9", "#2c7bb6"), 
            title="Drought index", breaks = c(-10, -2, -1.5, -1, 1, 1.5, 2, 10)) + 
  tm_shape(provborders_sp) + tm_dots(NA) +
  tm_legend(legend.outside=FALSE, legend.position = c("left", "center"))

# Export these files

tmap_save(raster2012, filename = file.path(maps,"raster2012.png"))
tmap_save(raster2013, filename = file.path(maps,"raster2013.png"))
tmap_save(raster2014, filename = file.path(maps,"raster2014.png"))
tmap_save(raster2015, filename = file.path(maps,"raster2015.png"))
tmap_save(raster2016, filename = file.path(maps,"raster2016.png"))

# Interpolate SPEI data for NDHS points

# Load NDHS data and convert to a shape file
ndhs <- read_dta("/Users/angelosantos/Library/CloudStorage/OneDrive-GeorgeMasonUniversity-O365Production/PUBP 833/Datasets/Processed/ndhs_birthmodule.dta")
ndhs_shp <- st_as_sf(ndhs, coords = c("LONGNUM", "LATNUM"), crs = 4326)

ndhs_merge_2015<- gstat::idw(mean_s12 ~ 1, spatialdata_2015_sp,
                                   newdata=ndhs_shp, idp=5) %>% rename(spei12_2015 = var1.pred)  %>% sf_to_df(fill = TRUE)

ndhs_merge_2016<- gstat::idw(mean_s12 ~ 1, spatialdata_2016_sp,
                             newdata=ndhs_shp, idp=5) %>% rename(spei12_2016 = var1.pred) %>% sf_to_df(fill = TRUE)

ndhs_final <- merge(x = ndhs_merge_2015, y = ndhs_merge_2016, by ="sfg_id", all = TRUE) %>%
  cbind(ndhs)

