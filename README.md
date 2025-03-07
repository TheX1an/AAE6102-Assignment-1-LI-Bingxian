**Assignment 1 Technical Report**

**Introduction**

The code of assignment 1 is uploaded in this repository. To run the GNSS
SDR to get the assignment results, just run the MATLAB script:
**main.m**. Four .mat files will be generated and saved after running
the script, which include:

- **Task_1_acquisition.mat,**

- **Task_2_tracking.mat,**

- **Task_3_navigation_data_decoding.mat,**

- **Task_4_5_position_and_velocity_estimation.mat.**

**Task_1_acquisition.mat,** corresponding to task 1 of this assignment,
saves the results of signal acquisition, which includes carrier
frequency, code phase, et al.

**Task_2_tracking.mat,** corresponding to task 2 of this assignment,
saves the results of signal tracking.

**Task_3_navigation_data_decoding.mat,** corresponding to task 3 of this
assignment, saves the results of navigation data decoding, which
includes TOW, ephemeris, et al.

**Task_4_5_position_and_velocity_estimation.mat,** corresponding to task
4 of this assignment, saves the results of position and velocity
estimation using WLS and EKF.

There are two datasets used in this assignment: **Open-Sky** and
**Urban**. So, to get the task results corresponding to these datasets,
one should run the **main.m** two times. Each time with different
configurations. The differences are two folds. First, **the path of the
data file.** Second, **the IF frequency and sampling frequency**. All of
them can be changed simply by revising the code of **initSettings.m**
(function). The code that needs to be revised is shown below. Annotation
and unannotation are all you need.

<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image1.png">

In the subsequent sections of this report, the work and results of each
task in this assignment will be presented.

**Task 1 -- Acquisition**

In this task, an open-source GNSS SDR is implemented to perform GNSS
signal acquisition. The acquisition results of Open-Sky and Urban are
saved in corresponding **folders**: **Open-Sky** and **Urban**. The file
names are the same: **Task_1_acquisition.mat.**

Loading **Task_1_acquisition.mat,** one can get a struct **acqResults,**
which includes carrier frequencies, code phases, and correlation peak
ratios.

<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image2.png">

As one can see, the list of satellite to search for is 1:32.

**Task 2 -- Tracking**

In this task, an open-source GNSS SDR is implemented to perform GNSS
signal tracking. The tracking results of Open-Sky and Urban are saved in
corresponding **folders**: **Open-Sky** and **Urban**. The file names
are the same: **Task_2_tracking.mat.**

Loading **Task_2_tracking.mat,** one can get a struct **trkResults,**
which includes key information about the tracked signal.

<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image3.png">

As one can see, there are 12 channels.

The correlation results of signal tracking on the Open-Sky dataset are
shown below. It is evident that, in the case of GNSS signal tracking in
open sky areas, the prompt is much stronger than the early and late.
This indicates that there is less interference, such as multipath
effects.

<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image4.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image5.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image6.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image7.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image8.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image9.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image10.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image11.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image12.png">

The correlation results of signal tracking on the Urban dataset are
shown below. It is obvious that, in the case of GNSS signal tracking in
urban areas, the prompt is not evidently stronger than the early and
late. This indicates that there is more interference, such as multipath
effects. For example, in channel 12, 11, 9, 8, the early and late are
almost as strong as prompt, which indicates strong multipath
interference.

<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image13.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image14.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image15.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image16.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image17.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image18.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image19.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image20.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image21.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image22.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image23.png">
<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image24.png">

**Task 3 -- Navigation Data Decoding**

In this task, an open-source GNSS SDR is implemented to perform
navigation data decoding. The decoding results of Open-Sky and Urban are
saved in corresponding **folders**: **Open-Sky** and **Urban** with
name: **Task_3_navigation_data_decoding.mat.**

Loading **Task_3_navigation_data_decoding.mat,** one can get a struct
**dcdResults,** which includes TOW, ephemeris, et al.

<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image25.png">

**Task 4 -- Position and Velocity Estimation**

In this task, an open-source GNSS SDR is implemented to perform position
and velocity estimation using WLS. The estimation results of Open-Sky
and Urban are saved in corresponding **folders**: **Open-Sky** and
**Urban.** The name of the file is
**Task_4_5_position_and_velocity_estimation.mat.**

Loading **Task_4_5_position_and_velocity_estimation.mat,** one can get a
struct **navResults,** which includes positioning results: latitude_wls,
longitude_wls, and velocity estimation results: V_x_wls, V_y_wls,
V_z_wls, V_wls.

Receiver position of the Open-Sky dataset estimated by WLS is shown
below.

<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image26.png">

Receiver velocity of the Open-Sky dataset estimated by WLS is shown
below.

<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image27.png">

Receiver position of the Urban dataset estimated by WLS is shown below.

<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image28.png">

Receiver velocity of the Urban dataset estimated by WLS is shown below.

<img src="https://github.com/TheX1an/AAE6102-Assignment-1-LI-Bingxian/blob/main/media/image29.png">

Compared to the results from the Open-Sky dataset, the variance in
position and velocity estimations for the Urban dataset is significantly
larger, possibly due to the multipath and NLOS effects common in urban
environments. These interferences result in much higher estimation
errors in position and velocity, underscoring the need for advanced
positioning techniques such as multipath mitigation and NLOS estimation.

**Task 5 -- Kalman Filter-Based Positioning**

In this task, a self-developed EKF is implemented to estimate position
and velocity. The EKF implementation can be found in the file EKFPos.m.
However, as of the submission deadline for this assignment, there are
still issues with the implementation that result in inaccurate
positioning results. Further improvements are planned after the
assignment submission.

Currently, the estimation results of Open-Sky and Urban using this EKF
are saved in corresponding **folders**: **Open-Sky** and **Urban.** The
name of the file is **Task_4_5_position_and_velocity_estimation.mat.**

Loading **Task_4_5_position_and_velocity_estimation.mat,** one can get a
struct **navResults,** which includes positioning results: X_ekf, Y_ekf,
Z_ekf, latitude_ekf, longitude_ekf, and velocity estimation results:
V_x_ekf, V_y_ekf, V_z_ekf.
