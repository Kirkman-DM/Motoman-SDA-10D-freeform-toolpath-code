clc
tic
%//////////////////////////////PARAMETERS////////////////////////////////
%File management
%Excel
XL_filename = 'SVR3';
%Output file name:
JobFile = 'N30.txt';
%Robot job name:
JobName = 'N30';
%////////////////////////////////////////////////////////////////////////
%Extrusion speeds settings in mm/min
ext_speed_1 = 180; sig_spd_1 = ["OFF" "OFF" "ON"];          %Priming
ext_speed_2 = 120; sig_spd_2 = ["OFF" "ON" "OFF"];          %Extrusion(0)
ext_speed_3 = 180; sig_spd_3 = ["OFF" "ON" "ON"];           %Extrusion(1)
ext_speed_4 = 120;  sig_spd_4 = ["ON" "OFF" "OFF"];         %Extrusion(2)
ext_speed_5 = 210; sig_spd_5 = ["ON" "OFF" "ON"];           %Extrusion(3)
ext_speed_6 = 48;  sig_spd_6 = ["ON" "ON" "OFF"];           %Extrusion(4)
ext_speed_7 = 240; sig_spd_7 = ["ON" "ON" "ON"];            %Retraction
Nozzle_dia = 3;                                             %mm
%////////////////////////////////////////////////////////////////////////
%Robot settings:
%Robot universal outputs:
Interrupt_out = 33;
Extruder_spd_out_1 = 34;
Extruder_spd_out_2 = 35;
Extruder_spd_out_3 = 36;
Lasers_out = 37;
LEDs_out = 38;
Tool = 12;
Tool_bed = [0.699 2.048  30.490  0.000  0.000  0.000  0.000];
%Robot coordinate points:
C_noz_tip = [-37.387, 768.190, 352.742, 0.0000, 0.0000, 0.0000, 0.0000];
C_UVBox_Target = [-309.929, 605.559, 424.927, 0.0000,0.0000,0.0000,0.000];
C_UVBox_Approach = [-309.929, 605.559, 325.000, 0.0000, 0.0000, 0.0000, 0.0000];
%Speed for in-between moves:
Calibration_speed_VJ = 25;      %MOVJ used for initial moves
Approach_Speed = 720;           %(mm/min)
UV_move_speed = 1080;           %(mm/min) for moves to the UV box
Inbetween_speed = 120;          %(mm/min)
z_end_spd = 120;                %(mm/min) for executing the end tools
Raise_speed = 600;              %(mm/min) Speed for executing z_drop_horiz
%Date for robot jobs:
dateTime = datetime('now','Format','yyyy/MM/dd HH:mm');
%////////////////////////////////////////////////////////////////////////
%Extrusion settings
%Initiation phase:
Prime_dist = 10;          %Extrusion length before bed starts moving
Prime_dist_flat = 15;     %For extrusions on bed
Prime_dist_off = 7.0;     %For extrusions of rank 3
Lights_off_dist = 3;      %Distance with bed moving before lights come on

%Termination:
Retraction_dist = 15;               
Stoppage_delay_orig = 3;           
z_set_dist = 1;                     
%wiping distances:
z_wipe_dist = 2.5;

%z-offsets / raise parameters:
z_end_dist_orig = 30;               
z_rise_1 = 20;                   
z_rise_2 = 20;                    
z_offset_bed = 1;         %Offset between nozzle and bed. 
z_twist_angle = 0;        %Deg
bump_dist = 40;           %Distance of approach point below extruder (mm)

%Diameter settings:
Dia_corr = 1.0;           %Correction factor for diameter variations.
%Diameter filter:
D_min = 0;
D_max = 7;

%Flat extrusion settings:
z_approach = 20;
UVBox_delay = 60;         %Delay for post curing in UV Box
z_drop_horiz = 30;                                                                                                                                                                                                                                                                                                                                                                                                                                                               (mm) Amount by which bed drops after horizontal extrusion
z_raise_dist_flat = Nozzle_dia-(Nozzle_dia/2 + z_offset_bed);   
%^Clearance distance for horizontal extrusions. 
%////////////////////////////////////////////////////////////////////////
%Inclination control settings:
%Inclination = 'Nonlinear';
Inclination = 'Linear';
incl = 100;                   %If linear inclination control is applied
lin_lim = 20*pi/180;          %Tangency retained up to this limit
zero_lim = 80*pi/180;         %Over this limit assume horizontal
%Parameters for horizontal extrusions
z_hgt_max = 4.0;              
%^Max z height from the base for horizontal extrusion parameters to be used
%////////////////////////////////////////////////////////////////////////
%Path Ranking:
Ranking = 'AUTO';
%Ranking = 'MANUAL';
%Rank allocations:
flat_on_bed = 1;
not_flat_on_bed = 2;
not_on_bed = 3;
%////////////////////////////////////////////////////////////////////////
%Collision avoidance:
%Approach collisions:
dist_approach = 10;     %For defining start tool distance above start point
%Endpt collisions:
search_rad = 1.5;       
nozzle_clearance = 8;   %Nozzle clearance from collision 
phi_increment = 0.25*pi/180;   
%^(deg) amount by which phi incrementally decreased to raise nozzle over collision
phi_slim = 25*pi/180;           
relax_index_length = 8;         
%////////////////////////////////////////////////////////////////////////
%Plotting / animation
Tracers = 'ON';    
Nozzle_tracers = 'OFF'; 
Dia_plot = 'OFF';      
Bed_side = 150;         
%////////////////////////////////////////////////////////////////////////
%Misc / soon to be removed
angle_lim = 0.001;      %deg
%////////////////////////////////////////////////////////////////////////

%////////////////////////////////////////////////////////////////////////

%////////////////////////////FUNCTIONS///////////////////////////////////
%Path-planner:
[Paths_planned, Paths_splitup_Reorg, Sorted_rank, Number_of_paths,...
    No_horizontal_paths, N_rows_per_path_post, PHI, THETA, PHI_inc,...
    PHI_inc_coll_a, PHI_inc_coll, THETA_inc, xy_check, coll_cell] = ...
    Path_planner_25_May_2020(XL_filename, z_hgt_max, lin_lim,...
    incl, Inclination, search_rad, nozzle_clearance, phi_increment,...
    phi_slim, Ranking, relax_index_length);

%Path-generator:
%Storage:
Tool_pose_ALL = cell(Number_of_paths,1);
Tool_end_comb_ALL = cell(Number_of_paths,1);
Tool_start_ALL = cell(Number_of_paths,1);
Prime_time_ALL = zeros(Number_of_paths, 1);
Retraction_time_ALL = zeros(Number_of_paths, 1);
Retraction_time_at_Prime_spd_ALL = zeros(Number_of_paths, 1);
Lights_off_time_ALL = zeros(Number_of_paths, 1);
n_lightsoff_ALL = zeros(Number_of_paths, 1);
Stoppage_delay_ALL = zeros(Number_of_paths, 1);
pts_prev = 1;                                         
Rx_ALL = cell(Number_of_paths,1);
Ry_ALL = cell(Number_of_paths,1);
Dia_disc_ALL = cell(Number_of_paths,1);
delta_Ry_ALL = cell(Number_of_paths,1);

for t = 1 : Number_of_paths
    [Tool_pose_fetched, Prime_time, Retraction_time,...
        Retraction_time_at_Prime_spd, Lights_off_time, n_lightsoff,...
        Stoppage_delay, Tool_end_comb,Tool_start, Rx, Ry, Dia_disc,...
        delta_Ry] = Path_generator_25_May_2020(Paths_planned{t},...
        N_rows_per_path_post(t), N_rows_per_path_post, Number_of_paths,...
        t, ext_speed_1, ext_speed_3,ext_speed_4, ext_speed_7,...
        Prime_dist, Prime_dist_flat, Prime_dist_off, Retraction_dist,...
        Lights_off_dist,z_offset_bed, z_end_dist_orig,...
        z_raise_dist_flat, bump_dist, lin_lim, zero_lim, z_hgt_max,...
        z_set_dist, C_noz_tip, C_UVBox_Target, C_UVBox_Approach,...
        z_wipe_dist, Tool_bed, angle_lim, Stoppage_delay_orig,...
        pts_prev, z_drop_horiz, dist_approach, z_rise_1, z_rise_2,...
        incl, Inclination, Sorted_rank(t), No_horizontal_paths,...
        Nozzle_dia, D_min, D_max, Dia_corr, z_approach, z_twist_angle);
    
    
    Tool_pose_ALL(t) = {Tool_pose_fetched};
    Prime_time_ALL(t) = Prime_time;
    Retraction_time_ALL(t) = Retraction_time;
    Retraction_time_at_Prime_spd_ALL(t) = Retraction_time_at_Prime_spd;
    Lights_off_time_ALL(t) = Lights_off_time;
    n_lightsoff_ALL(t) = n_lightsoff;
    Stoppage_delay_ALL(t) = Stoppage_delay;                              
    Tool_end_comb_ALL(t) = {Tool_end_comb};
    Tool_start_ALL(t) = {Tool_start};
    pts_prev = Tool_pose_fetched(N_rows_per_path_post(t), 1) + 5;        
    Rx_ALL(t) = {Rx};
    Ry_ALL(t) = {Ry};
    Dia_disc_ALL(t) = {Dia_disc};
    delta_Ry_ALL(t) = {delta_Ry};
end


%Write-job function
WriteJob_25_May_2020(Number_of_paths, N_rows_per_path_post, Tool_bed,...
    Tool_pose_ALL, Prime_time_ALL, Retraction_time_ALL,...
    Retraction_time_at_Prime_spd_ALL, JobName, JobFile,...
    dateTime, Tool, n_lightsoff_ALL, Stoppage_delay_ALL,...
    Tool_end_comb_ALL, Tool_start_ALL, z_end_spd, C_noz_tip,...
    Extruder_spd_out_1, Extruder_spd_out_2, Extruder_spd_out_3,...
    LEDs_out, Lasers_out, Interrupt_out,sig_spd_1, sig_spd_2,...
    sig_spd_3, sig_spd_4, sig_spd_5, sig_spd_6, sig_spd_7,...                          
    Calibration_speed_VJ, Approach_Speed, Inbetween_speed,...
    bump_dist, z_offset_bed, Raise_speed, Sorted_rank,...
    No_horizontal_paths, UVBox_delay, UV_move_speed);


%Animation function:
%Find limits:
x_min = zeros(1, Number_of_paths);
x_max = zeros(1, Number_of_paths);
y_min = zeros(1, Number_of_paths);
y_max = zeros(1, Number_of_paths);
z_max = zeros(1, Number_of_paths);
for u = 1 : Number_of_paths
    x_min(u) = min(Tool_pose_ALL{u}(:,2));
    x_max(u) = max(Tool_pose_ALL{u}(:,2));
    y_min(u) = min(Tool_pose_ALL{u}(:,3));
    y_max(u) = max(Tool_pose_ALL{u}(:,3));
    z_max(u) = max(Tool_pose_ALL{u}(:,4));
end
%Find the extreme values of these matrices:
X_MIN = min(x_min);
X_MAX = max(x_max);
Y_MIN = min(y_min);
Y_MAX = max(y_max);
Z_MAX = max(z_max);
%Then pre-allocate the size of image:
img = 1;
for y = 1 : Number_of_paths
    span = length(Tool_pose_ALL{y});
    for z = 1 : span + 5            
        image(img) = Animation_25_May_2020(Tracers, Nozzle_tracers,...
            Tool_bed, Tool_start_ALL, Tool_pose_ALL, Paths_planned,...
            Tool_end_comb_ALL, span, y, z, X_MIN, X_MAX, Y_MIN,...
            Y_MAX, Z_MAX, z_offset_bed, bump_dist, Dia_plot);   
        img = img + 1;
    end
end
%////////////////////////////////////////////////////////////////////////


%////////////////////////////PLOTS///////////////////////////////////////
%Plots for Rx, Rx_incl, Ry, Ry_incl//////////////////////////////////////
figure(2)
clf
for w = 1 : Number_of_paths
    %Rx pose
    Buffer_1 = 5;
    
    Rx_min = min(Rx_ALL{w}*180/pi);
    Rx_max = max(Rx_ALL{w}*180/pi);
    
    y_min_Rx = Rx_min - Buffer_1;
    y_max_Rx = Rx_max + Buffer_1;
    
    subplot(2,Number_of_paths,w)
    plot(round(Rx_ALL{w}*180/pi, 2));
    ylim([y_min_Rx y_max_Rx])
    xlabel('Iteration #')
    ylabel('Rx')
    title(['Path', num2str(w)])
    
    %Ry pose
    Ry_min = min(Ry_ALL{w}*180/pi);
    Ry_max = max(Ry_ALL{w}*180/pi);
    y_min_Ry = Ry_min - Buffer_1;
    y_max_Ry = Ry_max + Buffer_1;
    
    subplot(2,Number_of_paths,w + Number_of_paths)
    plot(round(Ry_ALL{w}*180/pi, 2));
    ylim([y_min_Ry y_max_Ry])
    xlabel('Iteration #')
    ylabel('Ry')
end

%Plots for theta and theta_inc///////////////////////////////////////////
figure(3)
clf
for e = 1 : Number_of_paths
    %Phi
    %Find y limits for the plots:
    Buffer_2 = 10;            %10 deg buffer on each side
    
    phi_min(1) = min(PHI{e}*180/pi);
    phi_min(2) = min(PHI_inc{e}*180/pi);
    phi_min(3) = min(PHI_inc_coll{e}*180/pi);
    phi_min(4) = min(PHI_inc_coll_a{e}*180/pi);
    phi_max(1) = max(PHI{e}*180/pi);
    phi_max(2) = max(PHI_inc{e}*180/pi);
    phi_max(3) = max(PHI_inc_coll{e}*180/pi);
    phi_max(4) = max(PHI_inc_coll_a{e}*180/pi);
    
    PHI_MIN = min(phi_min);
    PHI_MAX = max(phi_max);
    
    y_min_plot = PHI_MIN - Buffer_2;
    y_max_plot = PHI_MAX + Buffer_2;
    
    subplot(2, Number_of_paths, e)
    plot(round(PHI{e}*180/pi, 2), 'color', 'm')
    ylim([y_min_plot y_max_plot]);
    hold on
    plot(round(PHI_inc{e}*180/pi, 2), 'color', 'c')
    hold on
    plot(round(PHI_inc_coll{e}*180/pi, 2), 'color', 'k')
    hold on
    plot(round(PHI_inc_coll_a{e}*180/pi, 2), 'color', 'b')      
    xlabel('Iteration #')
    ylabel('phi (m), phi_{inc} (c), phi_{inc coll}(b) (deg)')
    title(['Path', num2str(e)])
    
    %Theta
    theta_min(1) = min(THETA{e}*180/pi);
    theta_min(2) = min(THETA_inc{e}*180/pi);
    theta_max(1) = max(THETA{e}*180/pi);
    theta_max(2) = max(THETA_inc{e}*180/pi);
    
    THETA_MIN = min(theta_min);
    THETA_MAX = max(theta_max);
       
    y_min_plot_2 = THETA_MIN - Buffer_2;
    y_max_plot_2 = THETA_MAX + Buffer_2;
    
    subplot(2, Number_of_paths,e + Number_of_paths)
    plot(round(THETA{e}*180/pi,2))
    ylim([y_min_plot_2 y_max_plot_2]);
    hold on
    plot(round(THETA_inc{e}*180/pi,2))
    xlabel('Iteration #')
    ylabel('theta & theta_{inc} (deg)')
end

%Plot of extrusion on bed////////////////////////////////////////////////
%Constants:
figure(4)
clf
title(JobName)
Bed_side = 80;
xlim([-Bed_side, Bed_side])
ylim([-Bed_side, Bed_side])
xlabel('X')
ylabel('Y')
zlabel('Z')

for p = 1 : Number_of_paths
    Curve = Paths_splitup_Reorg{p};
    plot3(Curve(:,1), Curve(:,2), Curve(:,3), 'LineWidth', 3,...
        'color', [(Number_of_paths - p + 1)/Number_of_paths 0 0])
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    hold on
end
axis equal
camva('manual');
hold on
%Now plot the bed:
[X,Y] = meshgrid(-Bed_side:150:Bed_side);
Z = 0*X + 0*Y;
surf(X,Y,Z)
colormap([1 1 1])
%shading interp;

disp('Job complete');
toc

%////////////////////////////////////////////////////////////////////////
%The animation playback
figure(5)
clf
movie(image, 1, 10)



