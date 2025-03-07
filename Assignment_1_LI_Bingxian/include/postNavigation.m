function [navSolutions, eph] = postNavigation(trackResults, acqResults, settings)
%Function calculates navigation solutions for the receiver (pseudoranges,
%positions). At the end it converts coordinates from the WGS84 system to
%the UTM, geocentric or any additional coordinate system.
%
%[navSolutions, eph] = postNavigation(trackResults, settings)
%
%   Inputs:
%       trackResults    - results from the tracking function (structure
%                       array).
%       acqResults      - results from the acquisition function (structure
%                       array).
%       settings        - receiver settings.
%   Outputs:
%       navSolutions    - contains measured pseudoranges, receiver
%                       clock error, receiver coordinates in several
%                       coordinate systems (at least ECEF and UTM).
%       eph             - received ephemerides of all SV (structure array).

%--------------------------------------------------------------------------
%                         CU Multi-GNSS SDR  
% (C) Updated by Yafeng Li, Nagaraj C. Shivaramaiah and Dennis M. Akos
% Based on the original work by Darius Plausinaitis,Peter Rinder, 
% Nicolaj Bertelsen and Dennis M. Akos
%--------------------------------------------------------------------------

%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or (at your option) any later version.
%
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%
%You should have received a copy of the GNU General Public License
%along with this program; if not, write to the Free Software
%Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
%USA.
%--------------------------------------------------------------------------

%CVS record:
%$Id: postNavigation.m,v 1.1.2.22 2006/08/09 17:20:11 dpl Exp $

%% Check is there enough data to obtain any navigation solution ===========
% It is necessary to have at least three subframes (number 1, 2 and 3) to
% find satellite coordinates. Then receiver position can be found too.
% The function requires all 5 subframes, because the tracking starts at
% arbitrary point. Therefore the first received subframes can be any three
% from the 5.
% One subframe length is 6 seconds, therefore we need at least 30 sec long
% record (5 * 6 = 30 sec = 30000ms). We add extra seconds for the cases,
% when tracking has started in a middle of a subframe.

if (settings.msToProcess < 36000) 
    % Show the error message and exit
    disp('Record is to short. Exiting!');
    navSolutions = [];
    eph          = [];
    return
end

%% Pre-allocate space =======================================================
% Starting positions of the first message in the input bit stream 
% trackResults.I_P in each channel. The position is PRN code count
% since start of tracking. Corresponding value will be set to inf 
% if no valid preambles were detected in the channel.
subFrameStart  = inf(1, settings.numberOfChannels);

% Time Of Week (TOW) of the first message(in seconds). Corresponding value
% will be set to inf if no valid preambles were detected in the channel.
TOW  = inf(1, settings.numberOfChannels);

%--- Make a list of channels excluding not tracking channels ---------------
activeChnList = find([trackResults.status] ~= '-');

%% Decode ephemerides =======================================================
for channelNr = activeChnList
    
    % Get PRN of current channel
    PRN = trackResults(channelNr).PRN;
    if settings.plotNavigation
        fprintf('Decoding NAV for PRN %02d -------------------- \n', PRN);
    end
    %=== Decode ephemerides and TOW of the first sub-frame ==================
    [eph(PRN), subFrameStart(channelNr), TOW(channelNr)] = ...
                                  NAVdecoding(trackResults(channelNr).I_P,settings);  %#ok<AGROW>

    %--- Exclude satellite if it does not have the necessary nav data -----
    if (isempty(eph(PRN).IODC) || isempty(eph(PRN).IODE_sf2) || ...
        isempty(eph(PRN).IODE_sf3) || (eph(PRN).health ~=0))

        %--- Exclude channel from the list (from further processing) ------
        activeChnList = setdiff(activeChnList, channelNr);
        fprintf('    Ephemeris decoding fails for PRN %02d !\n', PRN);
    else
        fprintf('    Three requisite messages for PRN %02d all decoded!\n', PRN);
    end
end

%% Check if the number of satellites is still above 3 =====================
if (isempty(activeChnList) || (size(activeChnList, 2) < 4))
    % Show error message and exit
    disp('Too few satellites with ephemeris data for postion calculations. Exiting!');
    navSolutions = [];
    eph          = [];
    return
end

%% Set measurement-time point and step  =====================================
% Find start and end of measurement point locations in IF signal stream with available
% measurements
sampleStart = zeros(1, settings.numberOfChannels);
sampleEnd = inf(1, settings.numberOfChannels);

for channelNr = activeChnList
    sampleStart(channelNr) = ...
          trackResults(channelNr).absoluteSample(subFrameStart(channelNr));
    
    sampleEnd(channelNr) = trackResults(channelNr).absoluteSample(end);
end

% Second term is to make space to aviod index exceeds matrix dimensions, 
% thus a margin of 1 is added.
sampleStart = max(sampleStart) + 1;  
sampleEnd = min(sampleEnd) - 1;

%--- Measurement step in unit of IF samples -------------------------------
measSampleStep = fix(settings.samplingFreq * settings.navSolPeriod/1000);

%---  Number of measurment point from measurment start to end ------------- 
measNrSum = fix((sampleEnd-sampleStart)/measSampleStep);

%% Initialization =========================================================
% Set the satellite elevations array to INF to include all satellites for
% the first calculation of receiver position. There is no reference point
% to find the elevation angle as there is no receiver position estimate at
% this point.
satElev  = inf(1, settings.numberOfChannels);

% Save the active channel list. The list contains satellites that are
% tracked and have the required ephemeris data. In the next step the list
% will depend on each satellite's elevation angle, which will change over
% time.  
readyChnList = activeChnList;

% Set local time to inf for first calculation of receiver position. After
% first fix, localTime will be updated by measurement sample step.
localTime = inf;

%##########################################################################
%#   Do the satellite and receiver position calculations                  #
%##########################################################################

fprintf('Positions are being computed. Please wait... \n');
for currMeasNr = 1:measNrSum

    fprintf('Fix: Processing %02d of %02d \n', currMeasNr,measNrSum);
    %% Initialization of current measurement ==============================          
    % Exclude satellites, that are belove elevation mask 
    activeChnList = intersect(find(satElev >= settings.elevationMask), ...
                              readyChnList);

    % Save list of satellites used for position calculation
    navSolutions.PRN(activeChnList, currMeasNr) = ...
                                        [trackResults(activeChnList).PRN]; 

    % These two lines help the skyPlot function. The satellites excluded
    % do to elevation mask will not "jump" to possition (0,0) in the sky
    % plot.
    navSolutions.el(:, currMeasNr) = NaN(settings.numberOfChannels, 1);
    navSolutions.az(:, currMeasNr) = NaN(settings.numberOfChannels, 1);
                                     
    % Signal transmitting time of each channel at measurement sample location
    navSolutions.transmitTime(:, currMeasNr) = ...
                                         NaN(settings.numberOfChannels, 1);
    navSolutions.satClkCorr(:, currMeasNr) = ...
                                         NaN(settings.numberOfChannels, 1);                                                                  
       
    % Position index of current measurement time in IF signal stream
    % (in unit IF signal sample point)
    currMeasSample = sampleStart + measSampleStep*(currMeasNr-1);
    
%% Find pseudoranges ======================================================
    % Raw pseudorange = (localTime - transmitTime) * light speed (in m)
    % All output are 1 by settings.numberOfChannels columme vecters.
    [navSolutions.rawP(:, currMeasNr),transmitTime,localTime]=  ...
                     calculatePseudoranges(trackResults,subFrameStart,TOW, ...
                     currMeasSample,localTime,activeChnList, settings);
    
    % Save transmitTime
    navSolutions.transmitTime(activeChnList, currMeasNr) = ...
                                        transmitTime(activeChnList);

%% Find satellites positions and clocks corrections =======================
    % Outputs are all colume vectors corresponding to activeChnList
    [satPositions, satClkCorr] = satpos(transmitTime(activeChnList), ...
                                 [trackResults(activeChnList).PRN], eph); 
                                    
     % Save satPositions
    navSolutions.satPositions{currMeasNr, 1} = satPositions;
    % Save satClkCorr
    navSolutions.satClkCorr(activeChnList, currMeasNr) = satClkCorr;

%% Find receiver position =================================================
    % 3D receiver position can be found only if signals from more than 3
    % satellites are available  
    if size(activeChnList, 2) > 3

        %=== Calculate receiver position ==================================
        % Correct pseudorange for SV clock error
        clkCorrRawP = navSolutions.rawP(activeChnList, currMeasNr)' + ...
                                                   satClkCorr * settings.c;

        % Calculate receiver position
        [xyzdt,navSolutions.el(activeChnList, currMeasNr), ...
               navSolutions.az(activeChnList, currMeasNr), ...
               navSolutions.DOP(:, currMeasNr), navSolutions.Amatrix{currMeasNr,1}] =...
                       leastSquarePos(satPositions, clkCorrRawP, settings);

        %=== Extract Carrier-to-Noise Ratios (C/N0) for Weighting =============
        % CNo = CNo';  % Ensure it's a column vector
        CNo = cell2mat(arrayfun(@(x) x.CNo.VSMValue(currMeasNr), ...
            trackResults(activeChnList), 'UniformOutput', false));

        % Calculate receiver position using WLS
        [WLSxyzdt,navSolutions.el(activeChnList, currMeasNr), ...
               navSolutions.az(activeChnList, currMeasNr), ...
               navSolutions.DOP(:, currMeasNr), navSolutions.Amatrix{currMeasNr,1}] =...
                       WLSPos(satPositions, clkCorrRawP, CNo, settings);

        %=== Extract carrier frequency for EKF =============
        carrFreq = acqResults.carrFreq(acqResults.carrFreq > 0); % Only detected satellites

        % Calculate receiver position using EKF
        [x_ekf, ~] = EKFPos(satPositions, clkCorrRawP, carrFreq, settings);

        %=== Save results ===========================================================
        % Receiver position in ECEF
        navSolutions.X(currMeasNr)      = xyzdt(1);
        navSolutions.Y(currMeasNr)      = xyzdt(2);
        navSolutions.Z(currMeasNr)      = xyzdt(3);

        % Receiver position using WLS in ECEF
        navSolutions.X_wls(currMeasNr)  = WLSxyzdt(1);
        navSolutions.Y_wls(currMeasNr)  = WLSxyzdt(2);
        navSolutions.Z_wls(currMeasNr)  = WLSxyzdt(3);

        % Receiver position and velocity using EKF in ECEF
        navSolutions.X_ekf(currMeasNr)   = x_ekf(1);
        navSolutions.Y_ekf(currMeasNr)   = x_ekf(2);
        navSolutions.Z_ekf(currMeasNr)   = x_ekf(3);
        navSolutions.V_x_ekf(currMeasNr)  = x_ekf(4);
        navSolutions.V_y_ekf(currMeasNr)  = x_ekf(5);
        navSolutions.V_z_ekf(currMeasNr)  = x_ekf(6);
        
        % Given position calculate velocity
        dT = settings.navSolPeriod / 1000; % [s]

        if currMeasNr > 1
            % Calculate x y z velocities
            navSolutions.V_x_wls(currMeasNr) = ...
                (navSolutions.X_wls(currMeasNr) - navSolutions.X_wls(currMeasNr - 1)) / dT;
            navSolutions.V_y_wls(currMeasNr) = ...
                (navSolutions.Y_wls(currMeasNr) - navSolutions.Y_wls(currMeasNr - 1)) / dT;
            navSolutions.V_z_wls(currMeasNr) = ...
                (navSolutions.Z_wls(currMeasNr) - navSolutions.Z_wls(currMeasNr - 1)) / dT;
            % Calculate velocities
            navSolutions.V_wls(currMeasNr) = sqrt( ...
                navSolutions.V_x_wls(currMeasNr)^2 + ...
                navSolutions.V_y_wls(currMeasNr)^2 + ...
                navSolutions.V_z_wls(currMeasNr)^2 ...
                );
        else
            % No velocity solution given only one position value
            navSolutions.V_x_wls(currMeasNr) = NaN;
            navSolutions.V_y_wls(currMeasNr) = NaN;
            navSolutions.V_z_wls(currMeasNr) = NaN;
            navSolutions.V_wls(currMeasNr) = NaN;
        end

		% For first calculation of solution, clock error will be set 
        % to be zero
        if (currMeasNr == 1)
        navSolutions.dt(currMeasNr) = 0;  % in unit of (m)
        else
            navSolutions.dt(currMeasNr) = xyzdt(4);  
        end
                
		%=== Correct local time by clock error estimation =================
        localTime = localTime - xyzdt(4)/settings.c;       
        navSolutions.localTime(currMeasNr) = localTime;
        
        % Save current measurement sample location 
        navSolutions.currMeasSample(currMeasNr) = currMeasSample;

        % Update the satellites elevations vector
        satElev = navSolutions.el(:, currMeasNr)';

        %=== Correct pseudorange measurements for clocks errors ===========
        navSolutions.correctedP(activeChnList, currMeasNr) = ...
                navSolutions.rawP(activeChnList, currMeasNr) + ...
                satClkCorr' * settings.c - xyzdt(4);
            
%% Coordinate conversion ==================================================

        %=== Convert to geodetic coordinates ==============================
        [navSolutions.latitude(currMeasNr), ...
         navSolutions.longitude(currMeasNr), ...
         navSolutions.height(currMeasNr)] = cart2geo(...
                                            navSolutions.X(currMeasNr), ...
                                            navSolutions.Y(currMeasNr), ...
                                            navSolutions.Z(currMeasNr), ...
                                            5);

        [navSolutions.latitude_wls(currMeasNr), ...
         navSolutions.longitude_wls(currMeasNr), ...
         navSolutions.height_wls(currMeasNr)] = cart2geo(...
                                            navSolutions.X_wls(currMeasNr), ...
                                            navSolutions.Y_wls(currMeasNr), ...
                                            navSolutions.Z_wls(currMeasNr), ...
                                            5);
        
        [navSolutions.latitude_ekf(currMeasNr), ...
         navSolutions.longitude_ekf(currMeasNr), ...
         navSolutions.height_ekf(currMeasNr)] = cart2geo(...
                                            navSolutions.X_ekf(currMeasNr), ...
                                            navSolutions.Y_ekf(currMeasNr), ...
                                            navSolutions.Z_ekf(currMeasNr), ...
                                            5);
        
        %=== Convert to UTM coordinate system =============================
        navSolutions.utmZone = findUtmZone(navSolutions.latitude(currMeasNr), ...
                                       navSolutions.longitude(currMeasNr));
        
        % Position in ENU
        [navSolutions.E(currMeasNr), ...
         navSolutions.N(currMeasNr), ...
         navSolutions.U(currMeasNr)] = cart2utm(xyzdt(1), xyzdt(2), ...
                                                xyzdt(3), ...
                                                navSolutions.utmZone);
        
        navSolutions.utmZone_wls = findUtmZone(navSolutions.latitude_wls(currMeasNr), ...
                                       navSolutions.longitude_wls(currMeasNr));
        
        % Position in ENU
        [navSolutions.E_wls(currMeasNr), ...
         navSolutions.N_wls(currMeasNr), ...
         navSolutions.U_wls(currMeasNr)] = cart2utm(WLSxyzdt(1), WLSxyzdt(2), ...
                                                WLSxyzdt(3), ...
                                                navSolutions.utmZone_wls);
        
    else
        %--- There are not enough satellites to find 3D position ----------
        disp(['   Measurement No. ', num2str(currMeasNr), ...
                       ': Not enough information for position solution.']);

        %--- Set the missing solutions to NaN. These results will be
        %excluded automatically in all plots. For DOP it is easier to use
        %zeros. NaN values might need to be excluded from results in some
        %of further processing to obtain correct results.
        navSolutions.X(currMeasNr)           = NaN;
        navSolutions.Y(currMeasNr)           = NaN;
        navSolutions.Z(currMeasNr)           = NaN;
        navSolutions.dt(currMeasNr)          = NaN;
        navSolutions.DOP(:, currMeasNr)      = zeros(5, 1);
        navSolutions.latitude(currMeasNr)    = NaN;
        navSolutions.longitude(currMeasNr)   = NaN;
        navSolutions.height(currMeasNr)      = NaN;
        navSolutions.E(currMeasNr)           = NaN;
        navSolutions.N(currMeasNr)           = NaN;
        navSolutions.U(currMeasNr)           = NaN;

        navSolutions.az(activeChnList, currMeasNr) = ...
                                             NaN(1, length(activeChnList));
        navSolutions.el(activeChnList, currMeasNr) = ...
                                             NaN(1, length(activeChnList));

        % TODO: Know issue. Satellite positions are not updated if the
        % satellites are excluded do to elevation mask. Therefore rasing
        % satellites will be not included even if they will be above
        % elevation mask at some point. This would be a good place to
        % update positions of the excluded satellites.
        
        disp('   Exit Program');
        return;


    end % if size(activeChnList, 2) > 3

    %=== Update local time by measurement  step  ====================================
    localTime = localTime + measSampleStep/settings.samplingFreq ;

end %for currMeasNr...
