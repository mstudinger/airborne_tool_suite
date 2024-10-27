# -*- coding: utf-8 -*-
"""
Initially created    : Mar  7, 2023
Restarted development: Oct 25, 2024 

@author: Michael Studinger, NASA - Goddard Space Flight Center

Purpose: create GeoDataFrame with range circle and return format independent GIS file name
See: https://geospace-code.github.io/pymap3d/vincenty.html#pymap3d.vincenty.vreckon

"""

# load needed modules

import os
import numpy as np
import pymap3d as pm
import geopandas as gpd
import pymap3d.vincenty as pmv
from   shapely.geometry import Polygon
from   astropy import units as u
u.imperial.enable()  


# define function

def range_to_gdf(
    lon_o:float,     # longitude of origin in decimal degrees
    lat_o:float,     # latitude  of origin in decimal degrees
    location:str,    # location name. e.g., airfield code such as "KLFI"
    platform:str,    # name of platform. e.g. "777", "DHC-6"
    max_range:float, # platform max_range. will be converted to out-and-back range.
    range_unit:str,  # distance unit for range. must be "nmi" or "km".
    ) -> object:     # GeoDataFrame with range circle and metadata and filename

    """
    Purpose     : create GeoDataFrame with range circle and return format independent GIS file name (no extension)
    Usage       : gdf, f_name = range_to_gdf(-76.360556,37.082778,'KLFI','777',3000,"nmi")
    Dependencies: os, numpy, pymap3d, geopandas, shapely, astropy
    """
    
    # check if critical input arguments are valid
    
    # 1) verify latitude of origin
    if (isinstance(float(lat_o), float) and (-90 <= lat_o <= 90)) == False:
        os.sys.exit("longitude of origin must be of type float and in decimal degrees (±90°)")
        
    # 2) verify longitude of origin
    # first wrap longitude to ±180°
    lon_o = np.mod(lon_o - 180.0, 360.0) - 180.0 
    if (isinstance(float(lon_o), float) and (-180 <= lon_o <= 180)) == False:
        os.sys.exit("longitude of origin must be of type float and in decimal degrees (±180°)")
        
    # 3) verify range_unit
    if (range_unit == "nmi" or range_unit == "km") == False:
        os.sys.exit("range_unit must be either 'nmi' or 'km'")
        
    # 4) verify max_range and convert to astropy object with range_unit
    if isinstance(float(max_range), float) and max_range > 0:
        if range_unit == "nmi":
            half_range = 0.5 * max_range * u.imperial.nmi
        elif range_unit == "km":
            half_range = 0.5 * max_range * u.imperial.km            
        # convert to meters for waypoint calculation
        half_range = half_range.to(u.m)        
    else:    
        os.sys.exit("max_range must be of type float and > 0")

    # create waypoints for half-range circe on WGS-8 ellipsoid
    wgs84 = pm.Ellipsoid.from_name('wgs84') # units are in meters
    azi = range(0,360,1)
    lat, lon = pmv.vreckon(lat_o, lon_o, half_range.to(u.m).value, azi, ell = wgs84)
    # need to wrap longitudes to ±180° for exporting geographic coordinates in GeoDataFrame
    # 0° to 360° is not supported
    lon = np.mod(lon - 180.0, 360.0) - 180.0
    
    # create GeoDataFrame for GIS export
    # convert waypoint coordinate arrays to lists needed for geometry field
    lat_point_list = list(lat); lon_point_list = list(lon)
    
    # set up geometry field
    polygon_geometry = Polygon(zip(lon_point_list, lat_point_list))
    
    # create GeoDataFrame with coordinate reference system and polygon geometry
    range_circle_gdf = gpd.GeoDataFrame(index = [0], crs = 'epsg:4326', geometry = [polygon_geometry])
    
    # add attributes (primarily used for labelling in QGIS)
    range_circle_gdf.loc[:, "label"] = platform + ' ' + f"{max_range*0.5:.0f}" + ' ' + range_unit + ' out-and-back range'
    range_circle_gdf.loc[:, "max_range_nmi"] = int(f"{max_range:.0f}")
    range_circle_gdf.loc[:, "range_nmi"] = half_range.to(u.imperial.nmi).value
    range_circle_gdf.loc[:, "range_km"]  = half_range.to(u.km).value
    range_circle_gdf.loc[:, "platform"]  = platform
    range_circle_gdf.loc[:, "location"]  = location
     
    # build format independent GIS output filename using input parameters
    f_name_gis = platform + '_' + location + '_' + f"{max_range:.0f}" + '_' + range_unit
    
    return range_circle_gdf, f_name_gis

# execute function as script, save GIS file and plot map and export as HTML file (optional)
if __name__ == '__main__':
    
    SAVE_GIS = True
    PLOT_MAP = True
    
    # set parameters
    # https://en.wikipedia.org/wiki/Langley_Air_Force_Base
    lat_o    =  37.082778
    lon_o    = -76.360556
    airfield = 'KLFI'
    platform = '777'
    max_range = 3000
    
    # execute function    
    range_circle_gdf, f_name = range_to_gdf(lon_o, lat_o, airfield, platform, max_range, "nmi")
    
    # save file in desired GIS format
    if SAVE_GIS:
        f_name_dir = r"..\..\data"
        f_name_short = f_name + '.gpkg'
        f_name_gis = os.path.join(f_name_dir,f_name_short)    
        range_circle_gdf.to_file(filename = f_name_gis, driver = "GPKG")
        
        print("\n\tAircraft  : %s" %(platform))
        print("\tRange [nm]: %d" %(max_range))
        print("\tSaved file: %s" %(f_name_short))
    
    # plot range circle with OpenStreetMap as basemap and save as HTML file
    if PLOT_MAP:
        folium_map = range_circle_gdf.explore()
        f_name_html = f_name_gis.replace('.gpkg','.html')
        folium_map.save(f_name_html)

    import webbrowser
    webbrowser.open(f_name_html)

