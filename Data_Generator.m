% =========================================================================
% VFM AS Training Project: Phase 1 & 2 - Synthetic Data Generator
% Multiphase Flow Metering (MPFM) Simulation (Oil, Water, Gas)
% =========================================================================

clear; clc; close all;

%% 1. Simulation Settings
Fs = 1;                     % Sampling frequency: 1 reading per second (1 Hz)
Duration_Hours = 24;        % Simulation duration: 24 hours
N = Duration_Hours * 3600;  % Total number of data points
Time = (1:N)' / 3600;       % Time array in hours

fprintf('Generating physical simulation for %d time steps...\n', N);

%% 2. Ground Truth Reservoir Conditions
% Simulating slow-changing real flow rates from the well
True_Total_Flow = 1500 + 200*sin(2*pi*Time/24); % Total Flow Rate (Barrels Per Day - BPD)
True_WLR = 0.35 * ones(N, 1);                  % Water Liquid Ratio (35%)
True_GVF = 0.60 * ones(N, 1);                  % Gas Volume Fraction (60%)

% Fluid physical properties (Densities in kg/m^3)
rho_oil = 850;   
rho_water = 1000; 
rho_gas = 1.2;    % Density at standard pressure conditions

%% 3. Dynamic Flow Disturbance (Slugging & Noise Generation)
% Real multiphase flow is unstable and suffers from gas/liquid slugging
Slugging_Effect = 0.15 * sin(2*pi*Time*12) .* (rand(N,1) > 0.7); 
True_GVF_with_Slugs = clip(True_GVF + Slugging_Effect, 0.05, 0.95);

%% 4. Physical Sensor Models (Forward Modeling)

% A. Mixture Density Calculation
Liquid_Density = (True_WLR .* rho_water) + ((1 - True_WLR) .* rho_oil);
Mixture_Density = ((1 - True_GVF_with_Slugs) .* Liquid_Density) + (True_GVF_with_Slugs .* rho_gas);

% B. Venturi Differential Pressure (dP) Sensor
% dP is proportional to mixture density and velocity squared (Bernoulli Effect)
Venturi_Constant = 1.2e-4; % Empirical calibration factor
Sensor_dP = Venturi_Constant .* Mixture_Density .* (True_Total_Flow.^2);
Sensor_dP = Sensor_dP + 5*randn(N,1); % Adding measurement white noise

% C. Electrical Impedance Sensor
% VFM measures electrical properties to derive WLR (Water is conductive, Oil is resistive)
Sensor_Impedance = 5000 ./ (1 + 15 * True_WLR) + 50*randn(N,1);

% D. Static Pressure & Temperature Sensors
Sensor_Pressure = 45 + 2*cos(2*pi*Time/24) + 0.5*randn(N,1); % in Bar
Sensor_Temperature = 65 + 1.5*sin(2*pi*Time/24) + 0.2*randn(N,1); % in Celsius

%% 5. Exporting Sensor Outputs for Analytics Phase
% Saving only raw sensor signals to simulate the cloud platform input
SensorData = table(Time, Sensor_Pressure, Sensor_Temperature, Sensor_dP, Sensor_Impedance);
save('Raw_Sensor_Data.mat', 'SensorData');
fprintf('Data successfully generated and saved to: Raw_Sensor_Data.mat\n');

%% 6. Data Visualization for Quality Check
figure('Name', 'VFM MPFM Sensor Simulation', 'NumberTitle', 'off');

subplot(3,1,1);
plot(Time, Sensor_dP, 'Color', [0.85 0.33 0.1]);
title('Venturi Differential Pressure (dP) Signal');
xlabel('Time (Hours)'); ylabel('dP (kPa)'); grid on;

subplot(3,1,2);
plot(Time, Sensor_Impedance, 'Color', [0 0.45 0.74]);
title('Electrical Impedance Sensor Signal');
xlabel('Time (Hours)'); ylabel('Impedance (\Omega)'); grid on;

subplot(3,1,3);
plot(Time, Sensor_Pressure, 'r', Time, Sensor_Temperature, 'g');
title('Static Line Pressure & Temperature');
xlabel('Time (Hours)'); ylabel('Values'); legend('Pressure (Bar)', 'Temp (^oC)'); grid on;

%% Helper Function for Data Clipping
function out = clip(in, min_val, max_val)
out = max(min(in, max_val), min_val);
end