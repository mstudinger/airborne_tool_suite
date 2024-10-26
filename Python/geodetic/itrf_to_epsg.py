# -*- coding: utf-8 -*-
"""
Created : Oct 21, 2024
Modified: Oct 26, 2024

@author: Michael Studinger, NASA - Goddard Space Flight Center

Returns 3D CRS EPSG code (in meters or degrees) for a given ITRF epoch:
    ITRF93, ITRF94, ITRF96, ITRF97, ITRF2000, ITRF2005, ITRF2008, ITRF2014, ITRF2020
    (as of October 2024)
    
For a list of official ITRF epoch names see: https://itrf.ign.fr/en/homepage
"""

def itrf_epoch_to_epsg(
        itrf_epoch:str,   # official name of ITRF epoch. For a list see https://itrf.ign.fr/en/homepage
        dist_unit:str,    # distance unit for EPSG code. Must be "deg" or "m".
        debug:bool=False  # True to print debugging information. False for no debug printout
        ) -> int:         # integer number for 3D CRS EPSG code if ITRF epoch was found. 2D CS are not (yet) supported.

      """
      Purpose: returns integer number with EPSG code for a given ITRF epoch.
      Usage  : epsg_code = itrf_epoch_to_epsg("ITRF93","m")
      For a list of supported ITRF epochs see: https://itrf.ign.fr/en/homepage
      For EPSG codes see: https://epsg.io/
      """
      
      import os
      
      if dist_unit == "m":      
          # 3D CRS in meters
          itrf_to_epsg = {
            'ITRF93'  : 4915,
            'ITRF94'  : 4916,
            'ITRF96'  : 4917,
            'ITRF97'  : 4918,
            'ITRF2000': 4919,
            'ITRF2005': 4896,
            'ITRF2008': 5332,
            'ITRF2014': 7789,
            'ITRF2020': 9988,
            }
          
      elif dist_unit == "deg":
          # 3D CRS in degrees
          itrf_to_epsg = {
            'ITRF93'  : 7905,
            'ITRF94'  : 7906,
            'ITRF96'  : 7907,
            'ITRF97'  : 7908,
            'ITRF2000': 7909,
            'ITRF2005': 7910,
            'ITRF2008': 7911,
            'ITRF2014': 7912,
            'ITRF2020': 9989,
            }
      else:
          os.sys.exit(f"Distance unit must be 'm' or 'deg'. '{dist_unit:s}' is not supported.")
      
      if itrf_epoch in itrf_to_epsg:
          epsg = int(itrf_to_epsg[itrf_epoch])
      else:
          os.sys.exit(f"ITRF epoch '{itrf_epoch}' is not supported.")
      
      return epsg

if __name__ == '__main__':
    
    # execute function for testing    
    epsg_m = itrf_epoch_to_epsg("ITRF94","m")
    print(f"EPSG code for 3D CRS in meters : {epsg_m:d}")

    epsg_deg = itrf_epoch_to_epsg("ITRF94","deg")
    print(f"EPSG code for 3D CRS in degrees: {epsg_deg:d}")
    


