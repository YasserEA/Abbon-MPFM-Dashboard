% =========================================================================
% VFM AS Training Project: Phase 3 - Data Analytics & Sensor Fusion
% Processing Raw Signals & Calculating Phase Flow Rates (Oil, Water, Gas)
% =========================================================================

clear; clc; close all;

%% 1. Load Raw Sensor Data
if ~exist('Raw_Sensor_Data.mat', 'file')
    error('Raw data file not found! Please run Data_Generator.m first.');
end

load('Raw_Sensor_Data.mat');
Time = SensorData.Time;
dP = SensorData.Sensor_dP;
Impedance = SensorData.Sensor_Impedance;

fprintf('Loading raw sensor signals for analytics processing...\n');

%% 2. Data Cleaning & Signal Smoothing (Removing Slugging Noise)
% Using moving average to clean sharp spikes caused by multiphase slugging
window_size = 60; % 1-minute smoothing window
Cleaned_dP = smoothdata(dP, 'movmean', window_size);
Cleaned_Impedance = smoothdata(Impedance, 'movmean', window_size);

%% 3. Sensor Fusion & Phase Flow Rate Extraction (Analytics Processing)
% Fluid physical constants (Must match the physics model)
rho_oil = 850;   
rho_water = 1000; 
rho_gas = 1.2;    
Venturi_Constant = 1.2e-4;

% A. Step 1: Reconstruct Water Liquid Ratio (WLR) from Impedance Inverse
Calculated_WLR = (5000 ./ Cleaned_Impedance - 1) / 15;
Calculated_WLR = max(min(Calculated_WLR, 1), 0); % Bound between 0 and 100%

% B. Step 2: Estimate Gas Volume Fraction (GVF)
Calculated_GVF = 0.60 * ones(size(Time)); 

% C. Step 3: Reconstruct Mixture Density
Calculated_Liquid_Density = (Calculated_WLR .* rho_water) + ((1 - Calculated_WLR) .* rho_oil);
Calculated_Mixture_Density = ((1 - Calculated_GVF) .* Calculated_Liquid_Density) + (Calculated_GVF .* rho_gas);

% D. Step 4: Calculate Total Flow Rate using the Venturi Formula
Calculated_Total_Flow = sqrt(max(Cleaned_dP, 0) ./ (Venturi_Constant .* Calculated_Mixture_Density));

%% 4. Individual Phase Flow Allocation (Oil, Water, Gas Rates)
Gas_Flow_Rate = Calculated_Total_Flow .* Calculated_GVF;
Liquid_Flow_Rate = Calculated_Total_Flow .* (1 - Calculated_GVF);

Oil_Flow_Rate = Liquid_Flow_Rate .* (1 - Calculated_WLR);
Water_Flow_Rate = Liquid_Flow_Rate .* Calculated_WLR;

%% 5. Export Processed Analytics Results
AnalyticsResult = table(Time, Calculated_Total_Flow, Oil_Flow_Rate, Water_Flow_Rate, Gas_Flow_Rate, Calculated_WLR);
save('Analytics_Results.mat', 'AnalyticsResult');
fprintf('Analytics complete! Processed output saved to: VFM_Analytics_Results.mat\n');

%% 6. Plotting Production Performance Trends
figure('Name', 'AnalyticS - Production Monitoring', 'NumberTitle', 'off');

subplot(2,1,1);
plot(Time, Oil_Flow_Rate, 'g', 'LineWidth', 1.5); hold on;
plot(Time, Water_Flow_Rate, 'b', 'LineWidth', 1.5);
title('Calculated Liquid Production Rates');
xlabel('Time (Hours)'); ylabel('Flow Rate (Barrels/Day)');
legend('Net Oil Rate', 'Produced Water Rate'); grid on;

subplot(2,1,2);
plot(Time, Gas_Flow_Rate, 'm', 'LineWidth', 1.5);
title('Calculated Gas Production Rate');
xlabel('Time (Hours)'); ylabel('Gas Rate (Standard Cubic Feet/Day)');
legend('Associated Gas'); grid on;