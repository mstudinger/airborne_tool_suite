% calculate turn radius based on speed and bank angle

clear;

format long g;


g = 9.81; % in m/s^2
%v_kts = 250; % in kts

v_kts = 200:1:300;
theta = 15; % banking angle in degrees


v_ms = nm2km(v_kts).*1000/(60*60);
v_kmh = nm2km(v_kts);

r_km = ((v_ms).^2./(g .*  tan(deg2rad(theta))))./1000;

% u turn distance:
% circumference(diameter)

dist_m = (2.*pi.*r_km./2).*1000;

time_s = dist_m./v_ms;

time_min = time_s./60;



%% plot figures

edge = 50; scrsz = get(0,'ScreenSize');  % for testing
fig1 = figure('Position',[edge edge (scrsz(3)-2*edge) (scrsz(4)-3*edge)]);

subplot(2,2,1);
plot(v_kts,km2nm(r_km),'b-'); grid on;
xlabel('Aircraft Speed [kts]'); ylabel('Turn radius [nm]');

subplot(2,2,2);
plot(v_kts,time_min,'r-'); grid on;
xlabel('Aircraft Speed [kts]'); ylabel('Time for half turn [mins]');

subplot(2,2,3);
plot(v_kts,km2nm(dist_m/1000),'r-'); grid on;
xlabel('Aircraft Speed [kts]'); ylabel('Distance in half turn [nm]');

subplot(2,2,4);
plot(v_kts,1.5*time_min,'r-'); grid on;
xlabel('Aircraft Speed [kts]'); ylabel('Time for 270 \circ turn [mins]');


%%

fig2 = figure('Position',[edge edge (scrsz(3)-2*edge) (scrsz(4)-3*edge)]);
subplot(2,2,1);
plot(v_kts,1.5*km2nm(dist_m/1000),'r-'); grid on;
xlabel('Aircraft Speed [kts]'); ylabel('Distance for 270 \circ turn [nm]');

subplot(2,2,2);
plot(v_kts,1.5*time_min*60,'r-'); grid on;
xlabel('Aircraft Speed [kts]'); ylabel('Time for 270 \circ turn [secs]');










