# -*- coding: utf-8 -*-
"""
Initially created    : Mar  7, 2023
Restarted development: Oct 25, 2024 

@author: Michael Studinger, NASA - Goddard Space Flight Center

See:
    https://geospace-code.github.io/pymap3d/vincenty.html#pymap3d.vincenty.vreckon

"""

#%%
# =============================================================================
# load needed modules
# =============================================================================

import os
# import warnings
import numpy as np
import pymap3d as pm
import geopandas as gpd
import pymap3d.vincenty as pmv
from   shapely.geometry import Polygon
from   astropy import units as u
u.imperial.enable()  

# =============================================================================
# set airfield or location, range, and platform
# =============================================================================

# https://en.wikipedia.org/wiki/Langley_Air_Force_Base
lat_c    =  37.082778
lon_c    = -76.360556
airfield = 'KLFI'  # change to location for cover more applications
platform = '777'

max_range = 3000 * u.imperial.nmi
print(max_range.value, max_range.unit)
#max_range = max_range.to(u.m)
#print(max_range.value, max_range.unit)

#range_km = 3000 * 1.852 # * u.km # an astropy object with distance unit defined: range_km.unit
# convert to Nautical miles. need to enable imperial submodule first

# range_nm = range_km.to(u.imperial.nmi) # or nauticalmile or NM  

# platform = 'DC-3T'
# range_km = 900

# =============================================================================
# build output filename based on input parameters
# =============================================================================

f_name_dir  = r"..\..\data"

#f_name_short = platform + '_' + airfield + '_' + str(max_range.to(u.imperial.nmi).value) + '_km.shp'
f_name_short = platform + '_' + airfield + '_' + f"{max_range.value:.0f}" + '_' + str(max_range.unit) + '.gpkg'
f_name_gis   = os.path.join(f_name_dir,f_name_short)

import fiona
fiona.supported_drivers['KML'] = 'rw'


#%%
# =============================================================================
#  calculate waypoints for range circle on WGS-84 ellipsoid
# =============================================================================

wgs84 = pm.Ellipsoid.from_name('wgs84') # units are in meters
azi = range(0,360,1)

lat, lon = pmv.vreckon(lat_c, lon_c, max_range.to(u.m).value, azi, ell = wgs84)

# need to wrap longitudes to ±180° for exporting geographic coordinates
# 0° to 360° is not supported

lon = np.mod(lon - 180.0, 360.0) - 180.0

# print(np.min(lat))
# print(np.max(lon))

#%%
# =============================================================================
# prepare GeoDataFrame for GIS export
# =============================================================================

# convert waypoint coordinate arrays to lists needed for geometry field
lat_point_list = list(lat); lon_point_list = list(lon)

# set up geometry field
polygon_geometry = Polygon(zip(lon_point_list, lat_point_list))

# create GeoDataFrame with coordinate reference system and polygon geometry
range_circle_gdf = gpd.GeoDataFrame(index = [0], crs = 'epsg:4326', geometry = [polygon_geometry])

# add attributes (primarily used for labelling in QGIS)
range_circle_gdf.loc[:, "label"] = platform + ' ' + str(max_range.value) + ' nmi out-and-back range'
range_circle_gdf.loc[:, "range_nmi"] = max_range.value
range_circle_gdf.loc[:, "range_km"]  = max_range.to(u.km).value
range_circle_gdf.loc[:, "platform"]  = platform
range_circle_gdf.loc[:, "location"]  = airfield

#%%
# =============================================================================
# export shapefile
# =============================================================================

# range_circle_gdf.to_file(filename = f_name_shp, driver = "ESRI Shapefile")
range_circle_gdf.to_file(f_name_gis)
# range_circle_gdf.to_file(f_name_gis.replace('.gpkg','.kml'), driver='KML')

print("\n\tAircraft  : %s" %(platform))
print("\tRange [nm]: %d" %(max_range.value))
print("\tSaved file: %s" %(f_name_short))


#%% plot search polygon with OpenStreetMap as basemap adn save as HTML file

# https://python-visualization.github.io/folium/latest/user_guide/vector_layers/circle_and_circle_marker.html

import folium

f_name_dir  = r"..\..\html"
m = range_circle_gdf.explore()

folium.Marker(location=[lat_c, lon_c], popup=airfield).add_to(m)

# folium.Marker(
#     location=[45.3288, -121.6625],
#     tooltip="Click me!",
#     popup="Mt. Hood Meadows",
#     icon=folium.Icon(icon="cloud"),
# ).add_to(m)

# folium.Marker(
#     location=[45.3311, -121.7113],
#     tooltip="Click me!",
#     popup="Timberline Lodge",
#     icon=folium.Icon(color="green"),
# ).add_to(m)

radius = 3000
folium.Circle(
    location=[lat_c, lon_c],
    radius=radius,
    color="black",
    weight=1,
    fill_opacity=0.6,
    opacity=1,
    fill_color="green",
    fill=False,  # gets overridden by fill_color
    popup="{} meters".format(radius),
    tooltip="I am in meters",
).add_to(m)

# radius = 10000
# folium.Circle(
#     location=[-27.551667, -48.478889],
#     radius=radius,
#     color="black",
#     weight=1,
#     fill_opacity=0.6,
#     opacity=1,
#     fill_color="green",
#     fill=False,  # gets overridden by fill_color
#     popup="{} meters".format(radius),
#     tooltip="I am in meters",
# ).add_to(m)


f_name_html = os.path.join(f_name_dir,"range_map.html")
m.save(f_name_html)

#import webbrowser
#webbrowser.open(f_name_html)