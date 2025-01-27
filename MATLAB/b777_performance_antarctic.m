% B777_PERFORMANCE_ANTARCTIC.M
% 
% Joe MacGregor (NASA)
% Last updated: 14 January 2025

clear

plotting                    = false;

load('/Users/jamacgre/OneDrive - NASA/research/data/moa/new/moa750_narrow', 'moa750_narrow')

% BedMachine v3
BM							= struct;
BM.x						= double(ncread('/Users/jamacgre/OneDrive - NASA/research/data/antarctica/BedMachine/BedMachineAntarctica-v3.nc', 'x'))'; % projected x, m
BM.y						= double(flipud(ncread('/Users/jamacgre/OneDrive - NASA/research/data/antarctica/BedMachine/BedMachineAntarctica-v3.nc', 'y'))); % projected y, m
BM.mask						= double(rot90(ncread('/Users/jamacgre/OneDrive - NASA/research/data/antarctica/BedMachine/BedMachineAntarctica-v3.nc', 'mask'))); % mask

% simplified masks for whole Antarctica maps
BM.mask_combo				= BM.mask;
BM.mask(BM.mask < 2)		= 0;
BM.mask(BM.mask >= 2)		= 1;
BM.mask						= logical(BM.mask); % now mask is for ice sheet only

BM.mask_combo(BM.mask_combo == 4) ...
							= 2;

% MOA 2008-9 coastline/grounding-line/islands
moa_cl                      = shaperead('/Users/jamacgre/OneDrive - NASA/research/data/moa/new/moa_2009_coastline_v1.1.shp');
moa_gl                      = shaperead('/Users/jamacgre/OneDrive - NASA/research/data/moa/new/moa_2009_groundingline_v1.1.shp');
moa_il                      = shaperead('/Users/jamacgre/OneDrive - NASA/research/data/moa/new/moa_2009_islands_v1.1.shp');
[moa_gl.Lat, moa_gl.Lon]    = projinv(projcrs(3031), moa_gl.X(1:(end - 1)), moa_gl.Y(1:(end - 1)));

% MOA x/y limits for panel A inset display
[x_lim, y_lim]              = deal([min([moa_cl.X [moa_il(:).X]]) max([moa_cl.X [moa_il(:).X]])], [min([moa_cl.Y [moa_il(:).Y]]) max([moa_cl.Y [moa_il(:).Y]])]);

[~, moa_ref]				= readgeoraster('/Users/jamacgre/OneDrive - NASA/research/data/moa/new/moa750_2009_hp1_v1.1.tif');

%% 777 SPECIFIC CALCULATIONS

takeoff_penalty				= 15 / 60; %  time it takes to get on track following takeoff, hr
landing_penalty				= 15 / 60; % time it takes to get lined up for landing, hr
time_inc					= 5 / 60; % time increment, hr

aircraft                    = struct('Name',			{'NASA B777-200ER'}, ...
									 'NameShort',		{'777'}, ...
									 'MTOW',			{656e3}, ... % lb, maximum take-off weight
									 'OEW',				{321e3}, ... % lb, operating empty weight, incl. crew
									 'MissionLoad',		{50e3}, ... % lb, load for mission operations, QNCs + PAX + instruments
                                     'FuelTotal',		{308e3}, ... % lb, fuel total
									 'FuelTotalOp',		{280e3}, ... % lb, operational fuel total (if tanks not completely filled)
                                     'FuelReserveTime',	{90}, ... % min
									 'SpeedCruise',		{560}, ... % kt
									 'SpeedLo',			{275}, ... % kt
									 'SpeedLoPenalty',	{2}, ... % dimensionless, fuel burn penalty ratio for jet low-flying compared to cruise
									 'ETOPS',			{330}, ... % min, ETOPS for aircraft type (B777-200ER), not using yet
									 'PlotColor',		{'r'}); % plot color

num_aircraft                = length(aircraft);

% 777 specific stats from https://community.infiniteflight.com/t/your-guide-to-fuel-burn-and-cruising-altitudes-in-the-new-777-family-ignore-777f/488605
fuel_burn_per_load			= [0.1:0.1:1; (1e3 .* [8.5 9.0 10.4 10.9 11.8 12.4 13.2 14.1 14.9 15.8]); (1e3 .* [10.0 10.5 11.7 12.3 12.2 12.9 13.9 14.6 15.7 16.7])]; % row 1: percentage load; row 2: lowest burn rate in lbs/hr; row 3: lbs/hr higest of burn rates at that load
fuel_burn_per_load(4, :)	= mean(fuel_burn_per_load(2:3, :)); % mean of high and low

% loop through aircraft (only 1 presently)
for ii = 1:num_aircraft
	aircraft(ii).SpeedCruise= aircraft(ii).SpeedCruise .* unitsratio('m', 'nm'); % convert from kt to m/hr
	aircraft(ii).SpeedLo	= aircraft(ii).SpeedLo .* unitsratio('m', 'nm'); % convert from kt to m/hr
	aircraft(ii).WtStart	= aircraft(ii).OEW + aircraft(ii).MissionLoad + aircraft(ii).FuelTotalOp; % total starting weight
	aircraft(ii).WtSpare	= aircraft(ii).MTOW - aircraft(ii).WtStart; % spare (unused) weight, lb
	if (aircraft(ii).WtSpare < 0) % need some spare weight!
		error([aircraft(ii).Name ' too heavy (starting weight > MTOW'])
	end
	aircraft(ii).LoadMax	= aircraft(ii).MTOW - aircraft(ii).OEW; % max load, lb
	aircraft(ii).BurnRateHiRange ...
							= fuel_burn_per_load(4, :); % using internet #s from above
	aircraft(ii).BurnRateLoRange ...
							= aircraft(ii).SpeedLoPenalty .* fuel_burn_per_load(4, :); % penalty for low-flying with jet, based on G-V experience
	aircraft(ii).FuelReserveWt ...
							= (aircraft(ii).FuelReserveTime / 60) * interp1(0.1:0.1:1, aircraft(ii).BurnRateHiRange, ((aircraft(ii).OEW + aircraft(ii).MissionLoad + (0.2 * aircraft(ii).FuelTotalOp)) / aircraft(ii).LoadMax), 'linear', 'extrap'); % lb, assume at low load at end
	aircraft(ii).WtEnd		= aircraft(ii).OEW + aircraft(ii).MissionLoad + aircraft(ii).FuelReserveWt; % weight at end assuming we still have reserve
	aircraft(ii).LoadStart	= (aircraft(ii).WtStart - aircraft(ii).OEW) / aircraft(ii).LoadMax; % load ratio at start, dimensionless
	aircraft(ii).LoadEnd	= (aircraft(ii).WtEnd  - aircraft(ii).OEW) / aircraft(ii).LoadMax; % load ratio at end, dimensionless
end
aircraft					= orderfields(aircraft);

target                      = kml2struct('/Users/jamacgre/OneDrive - NASA/research/oib/deployment/2019_antarctic/flightplans/2019_Antarctic_targets.kml');
num_target                  = length(target);
[target(:).Latitude, target(:).Longitude] ...
                            = deal(target(:).Lat, target(:).Lon);
[x_tmp, y_tmp]              = projfwd(projcrs(3031), [target.Latitude], [target.Longitude]);
for ii = 1:num_target
    [target(ii).X, target(ii).Y] ...
                            = deal(x_tmp(ii), y_tmp(ii));
end
target                      = rmfield(target, {'BoundingBox' 'Description' 'Geometry' 'Lat' 'Lon'});
target(9).Name              = 'Francais GZ';
target(17).Name             = 'Sor Rondane GZ';
target						= orderfields(target);

base                        = struct('Name',        {'Punta Arenas' 'Ushuaia'   'Hobart'    'Perth'     'Cape Town'}, ...
                                     'Country',     {'CHL'          'ARG'       'AUS'       'AUS'       'ZAF'}, ...
									 'CountryNice', {'Chile'		'Argentina' 'Australia' 'Australia' 'South Africa'}, ...
                                     'ICAO',        {'SCCI'         'SAWH'      'YMHB'      'YPPH'      'FACT'}, ...
                                     'Latitude',    {-52.99         -54.84      -42.84      -31.94		-33.97}, ...
                                     'Longitude',   {-70.85         -68.30      147.51      115.96		18.60}, ...
                                     'Color',       {'k'            'r'         'b'         'm'			'g'});

num_base                    = length(base);

[x_base, y_base]            = projfwd(projcrs(3031), [base(:).Latitude], [base(:).Longitude]);
for ii = 1:num_base
    [base(ii).X, base(ii).Y]= deal(x_base(ii), y_base(ii));
    base(ii).NameLegend     = [base(ii).Name ' (' base(ii).ICAO ')'];
	base(ii).NameCountry    = [base(ii).Name ' (' base(ii).Country ')'];
end

deg_circle                  = (0:360)';
num_deg                     = length(deg_circle);

% too many targets picked along Wilkes Land coast
ind_target_show             = [1 2 5 8 11 12 15:22];

%%
for ii = 1:num_base
	
    base(ii).DistTransit    = distance(repmat([base(ii).Latitude base(ii).Longitude], num_target, 1), [[target(:).Latitude]' [target(:).Longitude]'], wgs84Ellipsoid); % transit distance, m
	
	% loop through each target and each aircraft, calculate fuel for transit to (starting from op full) and fuel for transit from (starting from reserve)
	[base(ii).TimeTransit, base(ii).FuelTransitOut, base(ii).FuelTransitReturn, base(ii).FuelTransit, base(ii).RangeSurvey] ...
							= deal(NaN(num_aircraft, num_target));
	[base(ii).XRangeCircle, base(ii).YRangeCircle] ...
							= deal(NaN(num_aircraft, num_target, num_deg));
	
	for jj = 1:num_target
		
		for kk = 1:num_aircraft
			
			base(ii).TimeTransit(kk, jj) ...
							= base(ii).DistTransit(jj) / aircraft(kk).SpeedCruise; % transit time, hr
			
			% initialize distance, fuel and load
			dist_curr		= 0;
			fuel_curr		= aircraft(kk).FuelTotalOp;
			load_curr		= aircraft(kk).LoadStart;
			
			% add in takeoff penalty
			for ll = 1:round(takeoff_penalty / time_inc)
				fuel_burn_curr ...
							= interp1(fuel_burn_per_load(1, :), aircraft(kk).BurnRateHiRange, load_curr, 'linear', 'extrap') * time_inc; % current fuel burn in lbs = rate (lbs/hr) * hr
				fuel_curr	= fuel_curr - fuel_burn_curr; % lbs available - lbs burned = lbs remaining
				load_curr	= load_curr - (fuel_burn_curr / aircraft(kk).LoadMax); % previous load - load just spent (which was all fuel)
			end
			
			% keep looping until you reach target
			while ((dist_curr < base(ii).DistTransit(jj)) && (fuel_curr > aircraft(kk).FuelReserveWt))
				dist_curr	= dist_curr + (time_inc * aircraft(kk).SpeedCruise); % hr * m/hr = m 
				fuel_burn_curr ...
							= interp1(0.1:0.1:1, aircraft(kk).BurnRateHiRange, load_curr, 'linear', 'extrap') * time_inc;
				fuel_curr	= fuel_curr - fuel_burn_curr;
				load_curr	= load_curr - (fuel_burn_curr / aircraft(kk).LoadMax);
			end
			base(ii).FuelTransitOut(kk, jj) ...
							= aircraft(kk).FuelTotalOp - fuel_curr;
			
			% now reverse starting from base on return, first adding in landing penalty
			dist_curr		= 0;
			fuel_curr		= aircraft(kk).FuelReserveWt;
			load_curr		= aircraft(kk).LoadEnd;
			for ll = 1:round(landing_penalty / time_inc)
				fuel_burn_curr ...
							= interp1(fuel_burn_per_load(1, :), aircraft(kk).BurnRateHiRange, load_curr, 'linear', 'extrap') * time_inc;
				fuel_curr	= fuel_curr + fuel_burn_curr;
				load_curr	= load_curr + (fuel_burn_curr / aircraft(kk).LoadMax);
			end
			while (dist_curr < base(ii).DistTransit(jj))
				dist_curr	= dist_curr + (time_inc * aircraft(kk).SpeedCruise);
				fuel_burn_curr ...
							= interp1(fuel_burn_per_load(1, :), aircraft(kk).BurnRateHiRange, load_curr, 'linear', 'extrap') * time_inc;
				fuel_curr	= fuel_curr + fuel_burn_curr;
				load_curr	= load_curr + (fuel_burn_curr / aircraft(kk).LoadMax);
			end
			base(ii).FuelTransitReturn(kk, jj) ...
							= fuel_curr - aircraft(kk).FuelReserveWt;
			
			base(ii).FuelTransit(kk, jj) ...
							= base(ii).FuelTransitOut(kk, jj) + base(ii).FuelTransitReturn(kk, jj); % total transit fuel, lb
			
			% skip if too far away
			if base(ii).FuelTransit(kk, jj) >= (aircraft(kk).FuelTotalOp - aircraft(kk).FuelReserveWt)
				continue
			end
			
			% calculate distance at survey altitude/speed on-station, 
			dist_curr		= 0;
			fuel_curr		= aircraft(kk).FuelTotalOp - base(ii).FuelTransitOut(kk, jj);
			load_curr		= aircraft(kk).LoadStart - (base(ii).FuelTransitOut(jj) / aircraft(kk).LoadMax);
			while (fuel_curr > base(ii).FuelTransitReturn(kk, jj)) % keep going until it's time to turn around
				dist_curr	= dist_curr + (time_inc * aircraft(kk).SpeedLo); % now use low-flying speed
				fuel_burn_curr ...
							= interp1(fuel_burn_per_load(1, :), aircraft(kk).BurnRateLoRange, load_curr, 'linear', 'extrap') * time_inc;
				fuel_curr	= fuel_curr - fuel_burn_curr;
				load_curr	= load_curr - (fuel_burn_curr / aircraft(kk).LoadMax);
			end
			base(ii).RangeSurvey(kk, jj) ...
                            = dist_curr; % full range survey
			[base(ii).XRangeCircle(kk, jj, :), base(ii).YRangeCircle(kk, jj, :)] ...
                            = deal((target(jj).X + (cosd(deg_circle) .* (base(ii).RangeSurvey(kk, jj) / 2))), (target(jj).Y + (sind(deg_circle) .* (base(ii).RangeSurvey(kk, jj) / 2)))); % out-and-back to circle
		end
	end
end
base						= orderfields(base);

%% GRIDDED SURVEY RANGE

ind_aircraft				= 1; % only one aircraft, not adding aircraft loop for now for simplicity

decim_bm					= 50;
x_decim						= BM.x(1:decim_bm:end);
y_decim						= BM.y(1:decim_bm:end);
[xx_decim, yy_decim]		= meshgrid(x_decim, y_decim);
[lat_decim, lon_decim]		= projinv(projcrs(3031), xx_decim, yy_decim);

mask_decim					= logical(BM.mask_combo(1:decim_bm:end, 1:decim_bm:end));

[dist_grd, range_grd, time_transit_grd] ...
							= deal(NaN(size(mask_decim, 1), size(mask_decim, 2), num_base));

for ii = 1:num_base
	dist_grd(:, :, ii)		= reshape(distance(repmat([base(ii).Latitude base(ii).Longitude], numel(mask_decim), 1), [lat_decim(:) lon_decim(:)], wgs84Ellipsoid), size(mask_decim)); % transit distance, m
end

ind_mask					= find(mask_decim);
[ind_mask_i, ind_mask_j]	= find(mask_decim);

for ii = 1:length(ind_mask)
	if ~mod(ii, 1e3)
		disp(1e2 * (ii / length(ind_mask)))
	end
	for jj = 1:num_base
		dist_curr			= 0;
		fuel_curr			= aircraft(ind_aircraft).FuelTotalOp;
		load_curr			= aircraft(ind_aircraft).LoadStart;
		for kk = 1:round(takeoff_penalty / time_inc)
			fuel_burn_curr	= interp1(fuel_burn_per_load(1, :), aircraft(ind_aircraft).BurnRateHiRange, load_curr, 'linear', 'extrap') * time_inc; % current fuel burn in lbs = rate (lbs/hr) * hr
			fuel_curr		= fuel_curr - fuel_burn_curr; % lbs available - lbs burned = lbs remaining
			load_curr		= load_curr - (fuel_burn_curr / aircraft(ind_aircraft).LoadMax); % previous load - load just spent (all fuel)
		end
		while ((dist_curr < dist_grd(ind_mask_i(ii), ind_mask_j(ii), jj)) && (fuel_curr > aircraft(ind_aircraft).FuelReserveWt))
			dist_curr		= dist_curr + (time_inc * aircraft(ind_aircraft).SpeedCruise); % hr * m/hr = m 
			fuel_burn_curr	= interp1(fuel_burn_per_load(1, :), aircraft(ind_aircraft).BurnRateHiRange, load_curr, 'linear', 'extrap') * time_inc; % current fuel burn in lbs = rate (lbs/hr) * hr
			fuel_curr		= fuel_curr - fuel_burn_curr; % lbs available - lbs burned = lbs remaining
			load_curr		= load_curr - (fuel_burn_curr / aircraft(ind_aircraft).LoadMax); % previous load - load just spent (all fuel)
		end
		fuel_transit_to_curr= aircraft(ind_aircraft).FuelTotalOp - fuel_curr;
		dist_curr			= 0;
		fuel_curr			= aircraft(ind_aircraft).FuelReserveWt;
		load_curr			= aircraft(ind_aircraft).LoadEnd;
		for kk = 1:round(landing_penalty / time_inc)
			fuel_burn_curr	= interp1(fuel_burn_per_load(1, :), aircraft(ind_aircraft).BurnRateHiRange, load_curr, 'linear', 'extrap') * time_inc; % current fuel burn in lbs = rate (lbs/hr) * hr
			fuel_curr		= fuel_curr + fuel_burn_curr; % lbs available + lbs burned = lbs remaining
			load_curr		= load_curr + (fuel_burn_curr / aircraft(ind_aircraft).LoadMax); % previous load + load just spent (all fuel)
		end
		while (dist_curr < dist_grd(ind_mask_i(ii), ind_mask_j(ii), jj))
			dist_curr		= dist_curr + (time_inc * aircraft(ind_aircraft).SpeedCruise); % hr * m/hr = m 
			fuel_burn_curr	= interp1(fuel_burn_per_load(1, :), aircraft(ind_aircraft).BurnRateHiRange, load_curr, 'linear', 'extrap') * time_inc; % current fuel burn in lbs = rate (lbs/hr) * hr
			fuel_curr		= fuel_curr + fuel_burn_curr; % lbs available + lbs burned = lbs remaining
			load_curr		= load_curr + (fuel_burn_curr / aircraft(ind_aircraft).LoadMax); % previous load + load just spent (all fuel)
		end
		fuel_transit_from_curr ...
							= fuel_curr - aircraft(ind_aircraft).FuelReserveWt;
		fuel_transit_tot_curr ...
							= fuel_transit_to_curr + fuel_transit_from_curr;
		if (fuel_transit_tot_curr > (aircraft(ind_aircraft).FuelTotalOp - aircraft(ind_aircraft).FuelReserveWt))
			continue
		end
		dist_curr			= 0;
		fuel_curr			= aircraft(ind_aircraft).FuelTotalOp - fuel_transit_to_curr;
		load_curr			= aircraft(ind_aircraft).LoadStart - (fuel_transit_to_curr / aircraft(ind_aircraft).LoadMax);
		while (fuel_curr > fuel_transit_from_curr) % keep going until it's time to turn around
			dist_curr		= dist_curr + (time_inc * aircraft(ind_aircraft).SpeedLo); % hr * m/hr = m
			fuel_burn_curr	= interp1(fuel_burn_per_load(1, :), aircraft(ind_aircraft).BurnRateLoRange, load_curr, 'linear', 'extrap') * time_inc; % current fuel burn in lbs = rate (lbs/hr) * hr
			fuel_curr		= fuel_curr - fuel_burn_curr; % lbs available - lbs burned = lbs remaining
			load_curr		= load_curr - (fuel_burn_curr / aircraft(ind_aircraft).LoadMax); % previous load - load just spent (all fuel)
		end
		range_grd(ind_mask_i(ii), ind_mask_j(ii), jj) ...
							= dist_curr; % full range survey
	end
end

%%
if plotting
%%    
    set(0, 'DefaultFigureWindowStyle', 'default')
    
%%
    set(0, 'DefaultFigureWindowStyle', 'docked')
    
%% TARGET CIRCLES

	ind_base_show			= 1:num_base;%[2 3 5]; % 1:num_base;
    figure('position', [50 50 1024 1024], 'Color', 'w')
    mapshow(moa750_narrow, moa_ref)
    axis equal
    axis image
	axis([moa_ref.XWorldLimits moa_ref.YWorldLimits])
    hold on
    line(moa_gl.X, moa_gl.Y, 'Color', 'w', 'LineWidth', 1)
    line(moa_cl.X, moa_cl.Y, 'Color', 'w', 'LineWidth', 1)
    for ii = 1:length(moa_il)
        line(moa_il(ii).X, moa_il(ii).Y, 'Color', 'w', 'LineWidth', 1)
    end
    line(-2.5e6, -2e6, 'Color', 'w', 'Marker', 'x', 'MarkerSize', 20, 'LineWidth', 5)
    line((-2.5e6 + (500e3 .* cosd(deg_circle))), (-2e6 + (500e3 .* sind(deg_circle))), 'Color', 'w', 'LineStyle', '--', 'LineWidth', 3)
    textborder(-2.5e6, (-2e6 + 250e3), {'500-km' 'survey radius'}, 'w', 'k', 'FontSize', 18, 'FontWeight', 'bold', 'HorizontalAlignment', 'center')
    for ii = ind_base_show
        for jj = ind_target_show
            if ~isnan(base(ii).RangeSurvey(ind_aircraft, jj))
                line(squeeze(base(ii).XRangeCircle(ind_aircraft, jj, :)), squeeze(base(ii).YRangeCircle(ind_aircraft, jj, :)), 'LineWidth', 3, 'Color', base(ii).Color)
            end
        end
    end
    for ii = ind_target_show
        line(target(ii).X, target(ii).Y, 'Color', 'k', 'Marker', 'x', 'MarkerSize', 20, 'LineWidth', 4)
        textborder(target(ii).X, (target(ii).Y + 125e3), target(ii).Name, 'w', 'k', 'FontSize', 20, 'FontWeight', 'bold', 'HorizontalAlignment', 'center')
    end
    p_base                  = gobjects(1, length(ind_base_show));
    for ii = 1:length(ind_base_show)
        p_base(ii)          = line(NaN, NaN, 'LineWidth', 3, 'Color', base(ind_base_show(ii)).Color);
    end
    set(gca, 'FontSize', 20, 'FontWeight', 'bold', 'Layer', 'top', 'GridLineStyle', '-', 'GridColor', 'w', 'XTick', -3e6:5e5:2.5e6, 'YTick', -2.5e6:5e5:2e6)
	ax						= gca;
	ax.XTickLabel = ax.XTick ./ 1e3;
	ax.YTickLabel = ax.YTick ./ 1e3;
    xlabel('EPSG:3031 X (km)')
    ylabel('EPSG:3031 Y (km)')
    legend(p_base, {base(ind_base_show).Name}, 'Location',' northwest', 'FontSize', 16, 'FontWeight', 'bold');
    title('Preliminary Antarctic survey range-at-target estimates for NASA B777-200ER', 'FontWeight', 'bold', 'FontSize', 20)
    grid on
    box on
    
%% TARGET GRIDS

	ind_base_show			= [2 3 5];
    figure('position', [50 50 1600 600], 'Color', 'w')
	colormap(parula(20))
	ax						= gobjects(1, length(ind_base_show));
	for ii = 1:length(ind_base_show)
		ax(ii)				= subplot('position', [(0.01 + (0.31 * (ii - 1))) 0.01 0.305 0.91]);
    	mapshow(moa750_narrow, moa_ref)
    	axis equal image
		axis([-2.8e6 2.8e6 -2.3e6 2.3e6])
    	hold on
		for jj = 1:length(moa_il)
        	line(moa_il(jj).X, moa_il(jj).Y, 'Color', 'w', 'LineWidth', 1)
		end
		im					= imagesc(x_decim, y_decim, (range_grd(:, :, ind_base_show(ii)) ./ 2e3), 'AlphaData', (0.75 .* ~isnan(range_grd(:, :, ind_base_show(ii)))));
		clim([5e2 2.5e3])
    	line(moa_gl.X, moa_gl.Y, 'Color', 'w', 'LineWidth', 1)
    	line(moa_cl.X, moa_cl.Y, 'Color', 'w', 'LineWidth', 1)		
    	set(ax(ii), 'FontSize', 20, 'FontWeight', 'bold', 'Layer', 'top', 'GridLineStyle', '-', 'GridColor', 'w', 'XTick', -3e6:5e5:2.5e6, 'YTick', -2.5e6:5e5:2e6, 'XTickLabel', {}, 'YTickLabel', {})
    	title(['From ' base(ind_base_show(ii)).Name ', ' base(ind_base_show(ii)).CountryNice], 'FontWeight', 'bold', 'FontSize', 20)
		switch ii
			case 1
				text(-2.15e6, -1.8e6, '500 km', 'FontSize', 20, 'FontWeight', 'bold', 'Color', 'w')
				line([-2e6 -1.5e6], [-2e6 -2e6], 'Color', 'w', 'LineWidth', 6)
			case 2
				text(-4.0e6, 3.1e6, 'Preliminary range-at-target estimates for NASA B777-200ER', 'FontSize', 24, 'FontWeight', 'bold')
			case 3
				cb			= colorbar('Position', [0.94 0.13 0.015 0.67], 'FontSize', 20);
				cb.TickLabels{1} ...
							= ['<' cb.TickLabels{1}];
				cb.TickLabels{end} ...
							= ['>' cb.TickLabels{end}];
				text(2.85e6, 2.7e6, '(km)', 'FontSize', 20, 'FontWeight', 'bold')
		end
    	grid on
    	box on
	end
    
%%
end