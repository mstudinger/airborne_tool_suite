# -*- coding: utf-8 -*-
"""
Created on Nov 16, 2024

@author: Michael Studinger, NASA - Goddard Space Flight Center

Purpose: calculate turn radius of an aircraft based on speed and bank angle 

Note:    code translated and modified from MATLAB calc_turn_radius.m from 9/23/2016 
         on Nov 16, 2024
         
         g = 9.81;     % in m/s^2
         %v_kts = 250; % in kts

         v_kts = 200:1:300;
         theta = 15; % banking angle in degrees

         v_ms  = nm2km(v_kts).*1000/(60*60);
         v_kmh = nm2km(v_kts);

         r_km  = ((v_ms).^2./(g .*  tan(deg2rad(theta))))./1000;

         % u turn distance (180° turn):

         dist_m = (2.*pi.*r_km./2).*1000;
         time_s = dist_m./v_ms;
         time_min = time_s./60;

    
Also:    https://aviation.stackexchange.com/questions/2871/how-to-calculate-angular-velocity-and-radius-of-a-turn

Use this:https://www.faa.gov/regulations_policies/handbooks_manuals/aviation/phak
         The Handbook gives the formulas for rate of turn and turning radius
         on page 5-39 (right column) and figures 5-56 to 5-60:
         https://www.faa.gov/sites/faa.gov/files/07_phak_ch5_0.pdf    
         
         https://www.faa.gov/regulations_policies/handbooks_manuals/aviation
         https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/learn-about-aerodynamics/
         https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/banking-turns/
         
"""

import numpy as np
import matplotlib.pyplot as plt

from   astropy.constants import g0 as g # 9.81 - standard acceleration of gravity in m/s²
from   astropy import units as u
u.imperial.enable()  

one_nmi   = 1.0 * u.imperial.nmi
nmi_to_km = one_nmi.to(u.km)

# bank angle 
theta = 15  # bank angle in degrees

# array of true air speed (TAS) in knots
v_kts = np.arange(200, 301, 1)

# convert aeronautical units so SI units
v_kmh = v_kts * nmi_to_km
v_ms = v_kmh * 1000 / (60 * 60)

# calculations
r_km = (v_ms ** 2) / (g * np.tan(np.radians(theta))) / 1000
dist_m = 2 * np.pi * (r_km / 2) * 1000  # u-turn distance (180° turn) in meters
time_s = dist_m / v_ms  # time in seconds for half turn (180° turn)
time_min = time_s / 60  # time in minutes for half turn (180° turn)

# plotting
fig1, axs = plt.subplots(2, 2, figsize=(12, 10))
fig1.subplots_adjust(hspace=0.2)

# Subplot 1: Turn radius vs. Aircraft Speed
axs[0, 0].plot(v_kts, r_km / nmi_to_km, 'b-')
axs[0, 0].grid(True)
axs[0, 0].set_xlabel('Aircraft Speed [kts]')
axs[0, 0].set_ylabel('Turn Radius [nm]')

# Subplot 2: Time for half turn (180° turn) vs. Aircraft Speed
axs[0, 1].plot(v_kts, time_min, 'r-')
axs[0, 1].grid(True)
axs[0, 1].set_xlabel('Aircraft Speed [kts]')
axs[0, 1].set_ylabel('Time for Half Turn [mins]')

# Subplot 3: Distance in half turn vs. Aircraft Speed
axs[1, 0].plot(v_kts, (dist_m / 1000) / nmi_to_km, 'r-')
axs[1, 0].grid(True)
axs[1, 0].set_xlabel('Aircraft Speed [kts]')
axs[1, 0].set_ylabel('Distance in Half Turn [nm]')

# Subplot 4: Time for 270° turn vs. Aircraft Speed
axs[1, 1].plot(v_kts, 1.5 * time_min, 'r-')
axs[1, 1].grid(True)
axs[1, 1].set_xlabel('Aircraft Speed [kts]')
axs[1, 1].set_ylabel('Time for 270° Turn [mins]')

plt.show()

# # Second figure
# fig2, axs2 = plt.subplots(2, 1, figsize=(12, 10))
# fig2.subplots_adjust(hspace=0.4)

# # Subplot 1: Distance for 270° turn vs. Aircraft Speed
# axs2[0, 0].plot(v_kts, 1.5 * (dist_m / 1000) / nm_to_km, 'r-')
# axs2[0, 0].grid(True)
# axs2[0, 0].set_xlabel('Aircraft Speed [kts]')
# axs2[0, 0].set_ylabel('Distance for 270° Turn [nm]')

# # Subplot 2: Time for 270° turn vs. Aircraft Speed
# axs2[0, 1].plot(v_kts, 1.5 * time_min * 60, 'r-')
# axs2[0, 1].grid(True)
# axs2[0, 1].set_xlabel('Aircraft Speed [kts]')
# axs2[0, 1].set_ylabel('Time for 270° Turn [secs]')

# plt.show()
