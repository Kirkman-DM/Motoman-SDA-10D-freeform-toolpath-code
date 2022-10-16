
clc
tic
%File management 
    %Excel
    XL_filename = 'SQ_CT';    
    %Output file name:
    JobFile = 'SQCT';
    %Robot job name:
    JobName = 'SQCT-C4';
%//////////////////////////////////////////////////////////////////////////    
%Speed and signal settings in mm/s NOT mm/min anymore . . . 
    %Cutter engaging and disengaging speeds and signals:   
    cutter_eng_spd = 180;  %Cutter speeds are reference servo values  
    cutter_dis_spd = 60;    
    
    %Tool speed / extrusion speed (mm/s)
    Tool_speed = 1.5;       
    
%Nozzle settings:   
Nozzle_dia = 2.0;    
Bead_dia = 2.0; 

%Cutting settings: (see z_set_dist further down)
cut_offset = 0;                 %Nozzle offset from end of extrusion for laser curing of the cutting point (in direction of last vector)(set_dist is taken into account) 
laser_cut_cure_delay = 0.1;       %(s) Time delay for laser pulse on the cutting region 
fib_protrusion_dist = 8;        %Measured dist between nozzle exit and cutters in down position == dist of fibers protruding from nozzle after a cut
cutting_delay = 0.1;             %CUTTER DISCONNECTED!!!!!!!!!!! %(s) Amount of time that robot gives arduino to sort out the cutting operation (can be estimated using servo speeds)
nr_of_cuts = 1;                 %May need more than 1 cut to get through: 
pause_delay = 0.1;              %(s) Delay for the cutter to drop into place before cutting occurs 

%//////////////////////////////////////////////////////////////////////////   
%Robot settings:
    %Robot universal outputs: 
    Interrupt_out = 33;
    cutter_drop_pin = 34;
    cutter_engage_pin = 35;
    Arduino_out_3 = 36;                          %Free pin 
    Lasers_out = 37;                                         %DOUT#37 is reserved for the UV lasers . . . we will need a new one for the LEDs
    LEDs_out = 38;  %NOTE: need more ribbon cable connectors to sort this out && will need to get the relay and LEDs sorted 
    %Robot tool specification:
    Tool = 12;     
    Tool_bed = [0.126 -0.096  30.452  0.000  0.000  0.000  0.00];  %X, Y, Z, Rx, Ry, Rz, Re relative to flange coordinates
    %Robot coordinate points:
    C_noz_tip = [-34.999,652.941,321.979,0.0000,0.000,0.000,0.000];%[-34.999,652.941,321.979,0.9378,-0.5014,-0.0223,56.7629];%[-34.985,652.894,322.001,0.9366,-0.5022,-0.0368,56.7465];%[-35.278,652.112,362.699,0.8821,-0.4456,-0.0113,56.8587];%[-30.344,546.916,346.202,-39.0874,0.0318,-0.0362,56.8887]%[-29.866,649.011,305.276,0.00,0.00,0.00,57.000];   %[-28.869, 768.147, 302.518, 0, 0, 0, 0];%[-28.828,768.060,303.612,-0.0070,0.0011,0.0102,-0.0024];  %[-28.841, 768.014, 301.804, 0, 0, 0, 0]; %[-29.288,767.781,302.692, 0, 0, 0, 0]; %[-29.039, 767.246, 303.713, 0, 0, 0, 0];%[-29.917, 767.711, 304.912, 0, 0, 0, 0]; %[-30.458, 767.999, 303.170, 0.1611, 1.2495, -0.0370, 0.0492]; 
    C_UVBox_Target = [-309.929, 605.559, 424.927, 0.0000,0.0000,0.0000,0.000];
    C_UVBox_Approach = [-309.929, 605.559, 325.000, 0.0000, 0.0000, 0.0000, 0.0000];
    Re = 0;    %elbow angle in degrees
    
    %Speed for in-between moves:
    Calibration_speed_VJ = 40;                  %(%) MOVJ used for initial moves
    Approach_Speed = 15;                        %(mm/s)
    UV_move_speed = 18;                         %(mm/s) for moves to the UV box 
    Inbetween_speed = 12;                        %(mm/s)
    z_end_spd = 2.5;                            %(mm/s) for executing the end tools 
    Raise_speed = 12;                           %(mm/s) Speed for executing z_drop_horiz
    %Date for robot jobs:
    dateTime = datetime('now','Format','yyyy/MM/dd HH:mm');
%//////////////////////////////////////////////////////////////////////////    
%Extrusion settings   

    %Initiation: stickage delay 
    stickage_delay = 2;                   %x s delay between turning the lasers on and starting to move along the toolpath 
    %Termination: 
    Stoppage_delay_orig = 0.1;            %(s) before nozzle moves "away". Allows time for hardening of last segment
    set_dist = 2;                      %WAS3  %Dist from nozzle tip to imaginary setting points (in direction of last vector)
    
    %z-offsets / raise parameters:
    z_smear = fib_protrusion_dist + 1;  %Height of the start_tool above the start-point of the extrusion 
    z_end_dist_orig = 50;               %(mm)
    z_rise_postcut = 20;                %(mm) Distance nozzle rises in z direction after cutting has occurred. 
    z_offset_bed = 1.6;       %Was 1.2 for normal mode          %Offset between nozzle and bed. Ensures tool tip is always at nozzle tip. z_offset offsets the "virtual bed" from the real one
    bump_dist = 90;                     %Distance of approach point directly below extruder (mm) 
    
    %Horizontal offsets: 
    xy_smear = 20;
    
    %Flat extrusion settings
    UVBox_delay = 60;                             %Delay for post curing in UV Box  
    z_drop_horiz = 40;                            %                                                                                                                                                                                                                                                                                                                                                                                                                                   (mm) Amount by which bed drops after horizontal extrusion
    z_raise_dist_flat = Nozzle_dia-(Nozzle_dia/2 + z_offset_bed);   %Clearance distance for horizontal extrusions. Assumes a horiz extrusion dia of == Nozzle_dia
%//////////////////////////////////////////////////////////////////////////    
%Inclination control settings (for over-writing the phi and theta values):
    phi_manual_control = 'ON';
    theta_manual_control = 'ON';
    start_tool_sign = 1;      %+1 if the start tool comes in from the same direction as the initial nozzle tilt, otherwise -1
    %Call NTP_angles{:} to return values 
%NOTE: to disable set LINEAR and incl = 0
    %Inclination = 'Nonlinear';                       
    Inclination = 'Linear';
    incl = 0;                          %If linear inclination control is applied
    lin_lim = 20*pi/180;                %Tangency retained up to this limit
    zero_lim = 80*pi/180;               %Over this limit we assume that the extrusion is horizontal 
    %Parameters for horizontal extrusions
    z_hgt_max = 4.0;                %Max z height from the base for horizontal extrusion parameters to be used instead of normal extrusion 
    
%//////////////////////////////////////////////////////////////////////////        
%Path Ranking: 
%Ranking = 'AUTO';    
Ranking = 'MANUAL';
    %Rank allocations:
    flat_on_bed = 1;
    not_flat_on_bed = 2;
    not_on_bed = 3;
    
%Z-correction (to correct if the extrusion starts below the bed
    z_corr = 'ON';           %'OFF' %MUST BE ON FOR NORMAL EXTRUSION. . . ONLY OFF FOR GCODE GENERATION OR EXTRUSION WITH MODIFIED BED 
%//////////////////////////////////////////////////////////////////////////       
%Collision avoidance:   ///Set search rad to 0 to disable (but then it still runs through all the extra code)
    %Turn on or off:
    Coll_avoid = 'OFF';       %'OFF'
    %^^MUST be OFF if we are using manual values  . . . 
    %Approach collisions:
    dist_approach = 10;      %was 10, moved to 60 for the mitchell        %For defining start tool distance above start point (mm)    
    %Endpt collisions:
    %///CAN REMOVE MOST OF THESE . . . 
    search_rad = 5;                %Searching for collisions search radius == x  mm
    nozzle_clearance = 6;          %Was 10, made 12 for the tests on parallel straight %Nozzle clearance from collision point in ANY direction (replaces the below entries for now)
    phi_increment = 0.25*pi/180;   %(deg) amount by which phi incrementally decreased to raise nozzle over collision
    phi_slim = 20*pi/180;           %was 25, changed for straight parallel . . . %The phi angle below which we need to go over the other side . . .    
    relax_index_length = 8;         %Number of iterations after we pass a collision point for relaxing phi back to normal
%//////////////////////////////////////////////////////////////////////////       
%Plotting / animation
Tracers = 'ON';    %OR OFF   //To determine whether or not all tool moves are captured on the plot
Nozzle_tracers = 'OFF'; %OR OFF   //for the nozzle tracing code (per segment) to analyse nozzle tilt wrt the rest of the extrusions 
Bed_side = 150;         %Dimensions of bed used in plot 
%//////////////////////////////////////////////////////////////////////////
%Misc / soon to be removed 
angle_lim = 0.001;      %deg


%////////////////////////////FUNCTIONS/////////////////////////////////////
%Path-planner:
[Paths_planned, Paths_splitup_Reorg, Number_of_paths, N_rows_per_path_post, THETA_out, TCP_offset, NTP_angles] = Path_planner_16_Feb_2022(XL_filename,...
                                                                            z_hgt_max, lin_lim, incl, Inclination, Coll_avoid, search_rad, nozzle_clearance, phi_increment, phi_slim, Ranking, relax_index_length, Nozzle_dia, Bead_dia, theta_manual_control, phi_manual_control, z_corr);

%Path-generator:
    %Storage:
    Tool_pose_ALL = cell(Number_of_paths,1);                
    Tool_end_comb_ALL = cell(Number_of_paths,1);
    Tool_start_ALL = cell(Number_of_paths,1);
    Stoppage_delay_ALL = zeros(Number_of_paths, 1);
    pts_prev = 1;                                         %applies for the first path. To keep track of indexing
    Rx_ALL = cell(Number_of_paths,1);  
    Ry_ALL = cell(Number_of_paths,1);
    Dia_disc_ALL = cell(Number_of_paths,1);
    delta_Ry_ALL = cell(Number_of_paths,1);
    
for t = 1 : Number_of_paths
    [Tool_pose_fetched, Stoppage_delay, Tool_end_comb,Tool_start, Rx, Ry, delta_Ry] = Path_generator_16_Feb_2022(Re,Paths_planned{t},N_rows_per_path_post(t), N_rows_per_path_post,...
                                             Number_of_paths, t, Tool_speed, z_offset_bed, z_end_dist_orig, z_raise_dist_flat, bump_dist, lin_lim, zero_lim, z_hgt_max, set_dist,...
                                             cut_offset, fib_protrusion_dist, C_noz_tip, C_UVBox_Target, C_UVBox_Approach, Tool_bed, angle_lim, Stoppage_delay_orig, pts_prev, z_drop_horiz, dist_approach,...
                                             z_rise_postcut,Nozzle_dia, z_smear, xy_smear, NTP_angles{t}, start_tool_sign);      
                                         
                                         
    Tool_pose_ALL(t) = {Tool_pose_fetched};    
    Stoppage_delay_ALL(t) = Stoppage_delay;                              %Used as a check for horizontal extrusion . . .
    Tool_end_comb_ALL(t) = {Tool_end_comb};
    Tool_start_ALL(t) = {Tool_start};
    pts_prev = Tool_pose_fetched(N_rows_per_path_post(t), 1) + 5;        %Note: only called AFTER function (therefore prev applies . . .). pts_prev for t = 1 still zero . . .
    Rx_ALL(t) = {Rx};
    Ry_ALL(t) = {Ry};
    delta_Ry_ALL(t) = {delta_Ry};
end
 

%Write-job function //INFORM//
WriteJob_16_Feb_2022(Number_of_paths, N_rows_per_path_post, Tool_bed, Tool_pose_ALL, JobName, JobFile, dateTime, Tool, Stoppage_delay_ALL, Tool_end_comb_ALL, Tool_start_ALL,...
                        z_end_spd, C_noz_tip, cutter_drop_pin, cutter_engage_pin, Arduino_out_3, LEDs_out, Lasers_out, Interrupt_out,...
                        nr_of_cuts,laser_cut_cure_delay, cutting_delay, pause_delay, Calibration_speed_VJ, Approach_Speed, Inbetween_speed, bump_dist, z_offset_bed,...
                        Raise_speed, UVBox_delay, UV_move_speed, stickage_delay, Re);
                  

%GCODE conversion function using Paths_splitup_Reorg (before offsets are applied)  
%//Comment out if not needed//
Feed = 1000;             %Arbitrary feedrate for GCode 
e = 0.0001;              %Offset applied to avoid completely vert segments 
GCode_16_Feb_2022(Paths_splitup_Reorg, JobFile, Feed, e)


                    
                    %Vol-calc function:
%[Vol_ALL] = volCalc_25_May_2020(Tool_pose_ALL, Number_of_paths);           
                    
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
    for z = 1 : span + 5            %lenght - 1 (lose 1 pt)  +  5 (1 start point, 4 end points)
    %Animation function is called for each point 
    image(img) = Animation_16_Feb_2022(Tracers, Nozzle_tracers, Tool_bed, Tool_start_ALL, Tool_pose_ALL, Paths_planned, Tool_end_comb_ALL, span, y, z, X_MIN, X_MAX, Y_MIN, Y_MAX, Z_MAX, z_offset_bed, bump_dist);   %Make an image for each point in each toolpath . . .
    img = img + 1;
    end
end
%//////////////////////////////////////////////////////////////////////////


%////////////////////////////PLOTS/////////////////////////////////////////
%Plots for Rx, Rx_incl, Ry, Ry_incl////////////////////////////////////////
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


%Plots for theta and theta_inc/////////////////////////////////////////////
figure(3)
clf
% for e = 1 : Number_of_paths
% %Phi
%     %Find y limits for the plots:
%     Buffer_2 = 10;            %10 deg buffer on each side
%     
%     phi_min(1) = min(PHI_orig{e}*180/pi);
%     phi_min(2) = min(PHI_inc{e}*180/pi);
%     phi_min(3) = min(PHI_inc_coll{e}*180/pi);
%     phi_min(4) = min(PHI_inc_coll_a{e}*180/pi);
%     phi_max(1) = max(PHI_orig{e}*180/pi);
%     phi_max(2) = max(PHI_inc{e}*180/pi);
%     phi_max(3) = max(PHI_inc_coll{e}*180/pi);
%     phi_max(4) = max(PHI_inc_coll_a{e}*180/pi);
%     
%     PHI_MIN = min(phi_min);
%     PHI_MAX = max(phi_max);
%     
%     y_min_plot = PHI_MIN - Buffer_2;
%     y_max_plot = PHI_MAX + Buffer_2;
%     
%     subplot(2, Number_of_paths, e)
%     plot(round(PHI_orig{e}*180/pi, 2), 'color', 'm')
%     ylim([y_min_plot y_max_plot]);
%     hold on
%     plot(round(PHI_inc{e}*180/pi, 2), 'color', 'c')
%     hold on
%     plot(round(PHI_inc_coll{e}*180/pi, 2), 'color', 'k')
%     hold on
%     plot(round(PHI_inc_coll_a{e}*180/pi, 2), 'color', 'b')      %Before relaxation applied
%     xlabel('Iteration #')
%     ylabel('phi (m), phi_{inc} (c), phi_{inc coll}(b) (deg)')
%     title(['Path', num2str(e)])
%     
% %Theta
%     theta_min(1) = min(THETA_orig{e}*180/pi);
%     theta_min(2) = min(THETA_out{e}*180/pi);
%     theta_max(1) = max(THETA_orig{e}*180/pi);
%     theta_max(2) = max(THETA_out{e}*180/pi);
%     
%     THETA_MIN = min(theta_min);
%     THETA_MAX = max(theta_max);
%     
%     
%     y_min_plot_2 = THETA_MIN - Buffer_2;
%     y_max_plot_2 = THETA_MAX + Buffer_2;
%     
%     subplot(2, Number_of_paths,e + Number_of_paths)
%     plot(round(THETA_orig{e}*180/pi,2))
%     ylim([y_min_plot_2 y_max_plot_2]);
%     hold on
%     plot(round(THETA_out{e}*180/pi,2))
%     xlabel('Iteration #')
%     ylabel('theta & theta_{inc} (deg)')
% end


%Plot of extrusion on bed//////////////////////////////////////////////////
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
    Curve_1 = Paths_splitup_Reorg{p};
    plot3(Curve_1(:,1), Curve_1(:,2), Curve_1(:,3), 'LineWidth', 1, 'color', [(Number_of_paths - p + 1)/Number_of_paths 0 0])
    hold on
    Curve_2 = Paths_planned{p};
    plot3(Curve_2(:,1), Curve_2(:,2), Curve_2(:,3), 'LineWidth', 1, 'color', [0 (Number_of_paths - p + 1)/Number_of_paths 0])
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

%Plot the TCP offset
figure(5)
for h = 1 : Number_of_paths
    subplot(2, Number_of_paths, h)
    plot(TCP_offset{h})
    xlabel('Iteration')
    ylabel('TCP offset')
    ylim([0 Bead_dia/2])
    hold on  
end



%//////////////////////////////////////////////////////////////////////////
%The animation playback
% figure(6)
% clf
% movie(image, 1, 10)     



