"""
3bb_fig_S3_data_prep.py

Downloads MODIS and Landsat NDVI imagery for a set of validation districts via
Google Earth Engine and computes the modal peak-NDVI date for each district-year
and sensor. The resulting comparison table is used to produce Figure S3, which
validates MODIS-derived best dates against higher-resolution Landsat imagery.

Pipeline
--------
1. For each district in `districts_to_check` and each year in 2015–2019:
   a. Download MODIS (MOD13Q1, 250m, 16-day) and Landsat (8-day composite, 30m)
      NDVI and acquisition-date rasters for Jan–Jun, masked to agricultural pixels.
   b. Save per-tile GeoTIFF chips to `BEST_DATES_DIR/{modis,landsat}/`.
2. Read saved GeoTIFFs, spatially join pixels to districts, and compute the
   modal peak-NDVI date per district-year for each sensor.
3. Merge MODIS and Landsat results and write `figS3_landsat_modis_top10.csv`.

Required inputs
---------------
DISTRICT_GEO   Afghan district polygons (DISTID, PROV_34_NA, DIST_34_NA fields)
TILES_SHP      25 km grid tiles covering Afghanistan
Google Earth Engine account with access to MODIS/061/MOD13Q1 and
               LANDSAT/COMPOSITES/C02/T1_L2_8DAY_NDVI collections

Output
------
figS3_landsat_modis_top10.csv   One row per district-year with columns
                                 date_modis and date_landsat (YYYYMMDD integers)
"""

import ee

ee.Initialize()

import os
os.environ['USE_PYGEOS'] = '0'

import numpy as np
import pandas as pd
import geopandas as gpd
import json
import csv
import gc

from datetime import datetime, timedelta

from rasterio.plot import show
import rasterio
from rasterio.merge import merge
from rasterio.io import MemoryFile
from shapely.geometry import Point
import rioxarray as rxr

# ── Path configuration ──────────────────────────────────────────────────────
# Set SAT_ROOT to match your server environment before running.
SAT_ROOT = "/data/afg_satellite"

DISTRICT_GEO   = os.path.join(SAT_ROOT, "shp/district398_clean/district398.geojson")
TILES_SHP      = os.path.join(SAT_ROOT, "Grids/AFG_025_grid.shp")
BEST_DATES_DIR = os.path.join(SAT_ROOT, "revisions/bestDates")
FIGs3_OUT_CSV  = "figS3_landsat_modis_top10.csv"

##### Load some prelim files
ee_afg=ee.FeatureCollection("FAO/GAUL/2015/level0").filter(ee.Filter.eq('ADM0_NAME', 'Afghanistan'))
afg_shp    = gpd.read_file(DISTRICT_GEO)
tiles_25   = gpd.read_file(TILES_SHP)
helmand_shp = afg_shp[afg_shp.PROV_34_NA == 'Hilmand']

def shp_to_fc(file)->ee.FeatureCollection:
    """
    convert simple polygon/ shapefile to earth engine feature collection
    Note: doesn't seem to work very well with disjoint polygons/ nested polygons
    """
    g = [i for i in file.geometry]
    features=[]
    for i in range(len(g)):
        g = [i for i in file.geometry]
        x,y = g[i].exterior.coords.xy
        cords = np.dstack((x,y)).tolist()

        g=ee.Geometry.Polygon(cords)
        feature = ee.Feature(g)
        features.append(feature)
#     print("done")

    ee_object = ee.FeatureCollection(features)
    return ee_object

def addDate(image):
    date = ee.Date(image.get('system:time_start')).format('YYYYMMdd')
    dateBand = ee.Image(ee.Number.parse(date)).toInt().rename('date')
    return image.addBands(dateBand)

# This function adds a band representing the image timestamp.
def add_time(image):
  return image.addBands(image.getNumber('system:time_start'))

def cleanimg(image):
    return image.unmask(-9999)


start_date = "2015-01-01"
end_date = "2015-06-30"
modis_dates = pd.date_range(start_date, end_date, freq = '16D')
districts_to_check = [2205, 2302, 2301, 2407, 2416, 1906, 2307, 807, 805, 1115]

for dist in districts_to_check:
    dist_tiles = tiles_25.sjoin(afg_shp[afg_shp.DISTID == dist])
   
    print(dist_tiles.shape[0])
    for year in [2015]:
        start_date = f"{year}-01-01"
        end_date = f"{year}-06-30"
    
        print(year, datetime.now())
        ## Prepare Datasets

        ### landcover
        agDataset = ee.Image(f'COPERNICUS/Landcover/100m/Proba-V-C3/Global/{year}').select('discrete_classification');
        agMask = agDataset.select(['discrete_classification']).eq(40)

        ## modis
        mod_dataset = ee.ImageCollection("MODIS/061/MOD13Q1").filterDate(start_date, end_date).filterBounds(ee_afg)
        mod_dataset = mod_dataset.map(lambda x: x.unmask(-9999).select('NDVI'))
        mod_ndvi_date = mod_dataset.map(addDate).map(lambda x: x.updateMask(agMask).multiply(0.0001))


        ### landsat
        l8_dataset = ee.ImageCollection("LANDSAT/COMPOSITES/C02/T1_L2_8DAY_NDVI").filterDate(start_date, end_date).filterBounds(ee_afg)
        l8_dataset = l8_dataset.select(['NDVI']).map(addDate)
        l8_ndvi_date = l8_dataset.map(lambda x: x.updateMask(agMask))
        
        l8_maxNdvi = l8_ndvi_date.select('NDVI')
        l8_maxNdvi2 = l8_ndvi_date.qualityMosaic('NDVI')
        l8_acquisitionDate = l8_maxNdvi2.select('date')
        
        mod_maxNdvi = mod_ndvi_date.select('NDVI')
        mod_maxNdvi2 = mod_ndvi_date.qualityMosaic('NDVI')
        mod_acquisitionDate = mod_maxNdvi2.select('date')
    
        ## Export Imagery
        for img, bname, scale, outname in [(mod_maxNdvi2, 'NDVI', 250, 'modis'), 
                                           (mod_acquisitionDate, 'date', 250, 'modis'), 
                                           (l8_maxNdvi2, 'NDVI', 30, 'landsat'), 
                                           (l8_acquisitionDate, 'date', 30, 'landsat')]:
    
            print(outname)
            chips = []
            pth = os.path.join(BEST_DATES_DIR, outname)
            assert os.path.exists(pth)

            print("Downloading Tiles", start_date, datetime.now())
            for tile_id in dist_tiles['id'].unique():
                ee_dist = shp_to_fc(dist_tiles[dist_tiles.id == tile_id])
                mod_img = img.clipToBoundsAndScale(
                                                geometry=ee_dist, 
                                                scale = scale
                                              )
        
                if outname == 'modis':
                    mod_img = mod_img.reproject(crs = 'EPSG:4326', scale = scale )
            
                mod_img_ndvi = ee.data.computePixels({
                                "bandIds": [bname],
                                "expression": mod_img,
                                "fileFormat": 'GEOTIFF',
                            })
                chips.append(mod_img_ndvi)
        
            print("Merging Tiles", datetime.now())
            openchips = [MemoryFile(c).open() for c in chips]
            outimg, out_trans = merge(openchips)
            
            with rasterio.open(pth + "/" + f"{outname}_{bname}_{dist}_{year}_jan_june.tif", 'w', 
                       driver='GTiff', 
                       height=outimg.shape[1], 
                       width=outimg.shape[2], 
                       count=outimg.shape[0],
                       dtype=outimg.dtype,  
                       transform=out_trans) as dest:
                dest.write(outimg)

dfs = {'landsat':[], 
      'modis':[]}
for distid in districts_to_check:
    print(distid, datetime.now())
    for y in range(2015, 2020):
        print(y)
        for img_type in ['landsat', 'modis']:
            df = rxr.open_rasterio(os.path.join(BEST_DATES_DIR, img_type, f"{img_type}_date_{distid}_{y}_jan_june.tif"))
            # Covert our xarray.DataArray into a xarray.Dataset
            df = df.to_dataset('band')
            
            # Rename the variable to a more useful name
            df = df.rename({1: 'date'})
            df_long = df.to_dataframe()
            
            if img_type == 'landsat':
                df_long['date'] = df_long['date'].replace(-2147483648, np.nan)
                
            df_long = df_long.dropna()
            df_long = df_long[df_long['date'] != 0].copy()
            df_long = df_long.drop(columns = 'spatial_ref')
            df_long = df_long.reset_index()
            df_long = df_long.rename(columns = {'y':'latitude', 'x':'longitude'})
            
            
            geometry = [Point(xy) for xy in zip(df_long.longitude, df_long.latitude)]
            df_long = df_long.drop(columns = ['latitude', 'longitude'])
            gdf = gpd.GeoDataFrame(df_long, crs="EPSG:4326", geometry=geometry)
            
            gdf_dists = gdf.sjoin(afg_shp[afg_shp.DISTID.isin([distid])])
            best = gdf_dists.groupby(['PROV_34_NA', 'DIST_34_NA', 'DISTID', 'PROVID']).date.agg(pd.Series.mode)
            print(best.shape)
            best = best.reset_index()
            best['year'] = y
            dfs[img_type].append(best)


df_landsat = pd.concat(dfs['landsat'])
df_modis = pd.concat(dfs['modis'])
dfs = None
gc.collect()

df_final = df_modis.merge(df_landsat[['DISTID', 'year', 'date']], on = ['DISTID', 'year'], suffixes = ('_modis', '_landsat'))
df_final['date_modis'] = df_final['date_modis']*10000 ### because modis dates are formatted as yyyy.mmdd
df_final.to_csv(FIGs3_OUT_CSV, index = False)