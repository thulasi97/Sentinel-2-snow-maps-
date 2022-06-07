#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#Author: Thulasi Vishwanath Harish
#Last Update: 17.1.2022
#Description: This script aims to download Sentinel-2 satellite images from 
#Copernicus open access hub for a specified time period and pre-process the images
#before computing the Normalized Difference Snow Index (NDSI). Thereafter, 
#a threshold of 0.4 is applied to ndsi maps in order to obtain binary snow maps. 
#If ndsi > 0.4 --> pixel is classified as snow pixel, otherwise it is classified
#as no snow pixel. Upon classification, the percentage of snow cover present in 
#our area of interest is acquired and variations of snow cover over a time 
#period can be observed 
#1. Downloads Sentinel-2 data 
#2. Pre-processing the rasters - resampling 
#3. Processing - NDSI maps and Binary Snow maps 
#4. Visualization
#-------------------------------------------------------------------------------

#library
library(sf)
library(sen2r)
library(raster)
library(rgdal)
library(plyr)
library(ggplot2)

#packages
install.packages(c("leaflet", "leafpm", "mapedit", "shiny", "shinyFiles", "shinydashboard",
                   "shinyjs", "shinyWidgets"))

#-------------------------------------------------------------------------------
#1. Downloading S2 Images
#-------------------------------------------------------------------------------

#!!Provide details to LOGIN into Copernicus open access hub!!
sen2r()

#read the shapefile focusing on our area of interest 
studyArea = read_sf("C:/Users/Welcome/Desktop/Sample/Input/Martell_shp/Martell_valley.shp")

#!! Enter the desired time period!!
timePeriod <- as.Date(c("2017-01-01","2017-01-31"))

#Obtain a list of available Level 1C S2 products having maximum 90% cloud coverage  
L1C_s2_list <- s2_list(spatial_extent = studyArea, time_interval = timePeriod, max_cloud = 90, level = "L1C")

#download the available online S2 images 
s2_download(L1C_s2_list, outdir="C:/Users/Welcome/Desktop/Sample/s2_data")

#-------------------------------------------------------------------------------
#2.Preprocessing
#-------------------------------------------------------------------------------

setwd("C:/Users/Welcome/Desktop/Sample")

b3list = c(list.files(path = "./s2_data/", 
                      pattern=glob2rx("*_B03.jp2"),full.names=T, recursive = T,include.dirs = F))


b11list = c(list.files(path = "./s2_data/",
                       pattern=glob2rx("*_B11.jp2"),full.names=T, recursive = T,include.dirs = F))

#resample band3 and band 11 images to 10m resolution and mask them to the extent of our
#study area. Resampling is required because band 3 and band 11 have different resolution
for(i in 1:length(b3list)){
  gdal_warp( b3list[[i]],dstfile=file.path(paste0("./resample/B03/",substr(b3list[[i]], 130, 155),".tif")),
            mask= studyArea,tr = c(10, 10),dstnodata = 0, overwrite=F)
  gdal_warp( b11list[[i]],dstfile=file.path(paste0("./resample/B11/",substr(b11list[[i]], 130, 155),".tif")),
             mask= studyArea,tr = c(10, 10), dstnodata = 0, overwrite=F)
}

#-------------------------------------------------------------------------------
#3. Processing 
#-------------------------------------------------------------------------------

b3r = list()
b11r = list()

for(i in 1:length(b3list)){
  b3r[i] = raster(paste0("./resample/B03/",substr(b3list[[i]], 130, 155),".tif"))
  b11r[i] = raster(paste0("./resample/B11/",substr(b11list[[i]], 130, 155),".tif"))
}

b3stack =stack(b3r)
b11stack = stack(b11r)

#NDSI formula for Sentinel-2 (Band3 - Band11)/(Band3 + Band11)
ndsi = overlay(b3stack,b11stack, fun = function(x,y){((x-y)/(x+y))})

#From literature review, threshold of 0.4 is used to create binary snow maps
snowmap <- as.data.frame(calc(ndsi, function(x){ifelse(x>0.4,1,0)}), na.rm = T)

snow_cover = as.data.frame(matrix(nrow = 1, ncol = length(b3list)))

#Snow cover percentage 
for(i in 1:length(b3list)){
  snow_cover[1,i]=(sum(snowmap[[i]])/ncell(snowmap[[i]]))*100
}

#-------------------------------------------------------------------------------
#4. Visualization 
#-------------------------------------------------------------------------------

sensing_date = safe_getMetadata(L1C_s2_list, info = "sensing_datetime",format = "data.frame")
sensing_date$sensing_datetime <-data.frame(do.call('rbind', strsplit(as.character(sensing_date$sensing_datetime), ' ', fixed=T)))

snow_cover= t(snow_cover)
date_snow = as.data.frame(as.Date(sensing_date$sensing_datetime$X1[1:length(b3list)], format = "%Y-%m-%d"))
snow_cover= as.data.frame(cbind(date_snow, snow_cover))
colnames(snow_cover)= c("Date", "Snow Cover[%]")

ggplot( data = snow_cover, aes( Date,`Snow Cover[%]` )) + geom_line() + 
  theme(panel.background = element_rect(fill = "white", colour = "grey50"))+
  scale_x_date(date_labels = "%Y-%m-%d")

