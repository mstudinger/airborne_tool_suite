# -*- coding: utf-8 -*-
"""
Created on Tue Mar 7, 2023

@author: Michael Studinger, NASA Goddard Space Flight Center

"""

#%%
# =============================================================================
# load needed modules
# =============================================================================

import os, warnings
import numpy as np
import pymap3d as pm
import geopandas as gpd
import pymap3d.vincenty as pmv
from   shapely.geometry import Polygon

warnings.filterwarnings("ignore")  # suppresses all warnings - here used to suppress ShapelyDeprecationWarning from panda module

#%%
# =============================================================================
# set airfield, range, and platform
# =============================================================================

# https://en.wikipedia.org/wiki/Yellowknife_Airport
# lat_c =   62.463056
# lon_c = -114.440278
# airfield = 'CYZF'

# https://en.wikipedia.org/wiki/Yakutat_Airport
lat_c =   59.503333
lon_c = -139.660278
airfield = 'PAYA'

platform = 'DHC-6'
range_km = 500

# platform = 'DC-3T'
# range_km = 900

#%%
# =============================================================================
# build output filename based on input parameters
# =============================================================================

if os.path.exists(r"C:\Users\mstuding\OneDrive - NASA\EVS-4\location_map_QGIS_and_data\range_circles"): # my work laptop
    f_name_dir  = r"C:\Users\mstuding\OneDrive - NASA\EVS-4\location_map_QGIS_and_data\range_circles"
else:
    f_name_dir  = r""

f_name_short = platform + '_' + airfield + '_' + str(range_km) + '_km.shp'
f_name_shp   = os.path.join(f_name_dir,f_name_short)

#%%
# =============================================================================
#  calculate waypoints for range circle on WGS-84 ellipsoid
# =============================================================================

wgs84 = pm.Ellipsoid.from_name('wgs84')
azi = range(0,360,1)

lat, lon = pmv.vreckon(lat_c, lon_c, range_km*1000, azi, ell = wgs84)

# need to wrap longitudes to ±180 degrees for exporting geographic coordiantes.
# 0 to 360 is not supported.

lon = np.mod(lon - 180.0, 360.0) - 180.0

#%%
# =============================================================================
# prepare GeoDataFrame for shapefile export
# =============================================================================

# convert waypoint coordinate arrays to lists needed for geometry field
lat_point_list = list(lat); lon_point_list = list(lon)

# set up geometry field
polygon_geometry = Polygon(zip(lon_point_list, lat_point_list))

# create GeoDataFrame with coordinate reference system and polygon geometry
range_circle_gdf = gpd.GeoDataFrame(index = [0], crs = 'epsg:4326', geometry = [polygon_geometry])

# add attributes (primarily used for labelling in QGIS)
range_circle_gdf.loc[:, "label"] = platform + ' ' + str(range_km) + ' km out-and-back range'
range_circle_gdf.loc[:, "range_km"] = range_km
range_circle_gdf.loc[:, "platform"] = platform
range_circle_gdf.loc[:, "airfield"] = airfield

#%%
# =============================================================================
# export shapefile
# =============================================================================

range_circle_gdf.to_file(filename = f_name_shp, driver = "ESRI Shapefile")

print("\n\tAircraft  : %s" %(platform))
print("\tRange [km]: %d" %(range_km))
print("\tSaved file: %s" %(f_name_short))
