%% This script is used for Task 4 plotting.
clear
clc
close all

%% Load the .mat file to get the position and velocity estimation results
% 1) Open-Sky
% load("Open-Sky\Task_4_5_position_and_velocity_estimation.mat")
% 2) Urban
load("Urban\Task_4_5_position_and_velocity_estimation.mat")

%% Plot the receiver position
figure
marker_size = 80;
line_width = 1;
scatter( ...
    navResults.latitude_wls, navResults.longitude_wls, ...
    marker_size,"blue","x","LineWidth",line_width ...
    )
hold on
% % Ground truth for Open-Sky
% scatter( ...
%     22.328444770087565, 114.1713630049711, ...
%     marker_size,"red","x","LineWidth",line_width ...
%     )
% Ground truth for Urban
scatter( ...
    22.3198722, 114.209101777778, ...
    marker_size,"red","x","LineWidth",line_width ...
    )
grid on
legend("Position estimate","Ground truth")
title("Receiver position estimated by WLS (Urban)")
xlabel("Latitude [degree]")
ylabel("Longitude [degree]")

%% Plot the receiver velocity
figure
plot(navResults.V_x_wls,"LineWidth",line_width,"Color","g")
hold on
plot(navResults.V_y_wls,"LineWidth",line_width,"Color","b")
hold on
plot(navResults.V_z_wls,"LineWidth",line_width,"Color","c")
hold on
plot(navResults.V_wls,"LineWidth",line_width,"Color","m")
hold on
plot(zeros(1,size(navResults.V_wls,2)),"LineWidth",line_width,"Color","r")
hold on
grid on
legend("Vx","Vy","Vz","V=sqrt(Vx^2+Vy^2+Vz^2)","Ground truth")
title("Receiver velocities estimated by WLS (Urban)")
xlabel("Measurement period: 500ms")
ylabel("Velocities [m/s]")