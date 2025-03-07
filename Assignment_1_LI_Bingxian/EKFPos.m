function [x_est, P_est] = EKFPos(satPos, pseudorange, carrFreq, settings)
% Inputs:
%   pseudorange - Vector of pseudorange measurements (Nx1)
%   carrFreq    - Vector of carrier frequency shifts (Nx1)
%   satPos      - Matrix of satellite positions [X; Y; Z] (3xN)
%   settings    - Receiver settings
%
% Outputs:
%   x_est - Estimated state vector [x, y, z, vx, vy, vz, b, b_dot]
%   P_est - Estimated covariance matrix

% Initialization
c = 299792458; % Speed of light [m/s]
dt = settings.navSolPeriod / 1000; % Convert ms to seconds
num_states = 8; % [x, y, z, vx, vy, vz, b, b_dot]
num_satellite = size(satPos, 2);

% Compute Doppler shift from carrier frequency
IF = settings.IF; % Intermediate Frequency
f_L1 = 1.57542e9; % L1 GPS frequency [Hz]
doppler = -(carrFreq - IF) * c / f_L1;

% State Transition matrix
F = [
    1 0 0 dt 0  0  0    0;
    0 1 0 0  dt 0  0    0;
    0 0 1 0  0  dt 0    0;
    0 0 0 1  0  0  0    0;
    0 0 0 0  1  0  0    0;
    0 0 0 0  0  1  0    0;
    0 0 0 0  0  0  1    dt;
    0 0 0 0  0  0  0    1
    ];

% Initial state estimation
x_est = zeros(num_states, 1); % [x, y, z, vx, vy, vz, b, b_dot]

% Initial state Covariance matrix
P_est = eye(num_states) * 1e6;

% Process Noise Covariance
Q = diag([1, 1, 1, 10, 10, 10, 1e-2, 1e-4]);

% Measurement Noise Covariance matrix
R_pseudo = 10;
R_doppler = 1;
R = diag([R_pseudo*ones(1, num_satellite), R_doppler*ones(1, num_satellite)]);

% EKF prediction
x_pred = F * x_est;
P_pred = F * P_est * F' + Q; % Predicted covariance

% Initialize measurement model
H = zeros(2 * num_satellite, 8);
Z = zeros(2 * num_satellite, 1);
h_x = zeros(2 * num_satellite, 1);

for i = 1:num_satellite
    Xs = satPos(1, i);  Ys = satPos(2, i);  Zs = satPos(3, i);
    dX = Xs - x_pred(1);
    dY = Ys - x_pred(2);
    dZ = Zs - x_pred(3);
    rho = sqrt(dX^2 + dY^2 + dZ^2); % Range

    % Pseudorange Measurement
    H(i, :) = [-dX/rho, -dY/rho, -dZ/rho, 0, 0, 0, 1, 0];
    Z(i) = pseudorange(i);
    h_x(i) = rho + c * x_pred(7);

    % Doppler Measurement
    relVel = (dX*x_pred(4) + dY*x_pred(5) + dZ*x_pred(6)) / rho;
    H(num_satellite + i, :) = [0, 0, 0, -dX/rho, -dY/rho, -dZ/rho, 0, c];
    if i > length(doppler)  % Ensure index does not exceed doppler length
        Z(num_satellite + i) = 0;  % Assign zero if Doppler data is missing
    else
        Z(num_satellite + i) = doppler(i);
    end
    h_x(num_satellite + i) = relVel + c * x_pred(8);
end

% Innovation Calculation
y = Z - h_x;
S = H * P_pred * H' + R;
K = P_pred * H' / S; % Kalman Gain

% EFK update
x_est = x_pred + K * y;
P_est = (eye(8) - K * H) * P_pred;

% Result output
fprintf([ ...
    'Position = [%.2f, %.2f, %.2f], ' ...
    'Velocity = [%.2f, %.2f, %.2f]'
    ], ...
    x_est(1), x_est(2), x_est(3), ...
    x_est(4), x_est(5), x_est(6) ...
    );
end