# Sentinel-2-snow-maps
Batch downloading and processing Sentinel-2 images to binary snow maps.

This script aims to download Sentinel-2 satellite images from Copernicus open access hub for a specified time period and pre-process the images before computing the Normalized Difference Snow Index (NDSI). Thereafter, a threshold of 0.4 is applied to ndsi maps in order to obtain binary snow maps. 
If ndsi > 0.4 --> pixel is classified as snow pixel, otherwise it is classified as no snow pixel. Upon classification, the percentage of snow cover present in our area of interest is acquired and variations of snow cover over a time period can be observed. The following procedures are carried out:
1. Downloads Sentinel-2 data 
2. Pre-processing the rasters - resampling 
3. Processing - NDSI maps and Binary Snow maps 
4. Visualization
