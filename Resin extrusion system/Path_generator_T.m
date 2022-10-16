function [Tool_pose, Prime_time, Retraction_time,...
    Retraction_time_at_Prime_spd, Lights_off_time, n_lightsoff,...
    Stoppage_delay, Tool_end_comb,Tool_start, Rx, Ry, Dia_disc, delta_Ry]...
    = Path_generator_25_May_2020(pathN_points, N, N_rows_per_path,....
    Number_of_paths,path_position, ext_speed_1, ext_speed_3, ext_speed_4,...
    ext_speed_7, Prime_dist, Prime_dist_flat, Prime_dist_off,...
    Retraction_dist, Lights_off_dist,z_offset_bed,z_end_dist,...
    z_raise_dist_flat, bump_dist, lin_lim, zero_lim, z_hgt_max,...
    z_set_dist, C_noz_tip, C_UVBox_Target, C_UVBox_Approach,...
    z_wipe_dist, Tool_bed, angle_lim, Stoppage_delay_orig, pts_prev,...
    z_drop_horiz, dist_approach, z_rise_1, z_rise_2, incl, Inclination,...
    Rank, No_horizontal_paths, Nozzle_dia, D_min, D_max, Dia_corr,...
    z_approach, z_twist_angle)

%Extract the *current* points from paths_planned
    %These points correspond to the TCP points for the tool definition 
x_c = pathN_points(:, 1);                     
y_c = pathN_points(:, 2);
z_c = pathN_points(:, 3);
d_c = pathN_points(:, 4)*Dia_corr;  
N = numel(z_c);
N_lim = N;
%Extract the *tool direction* points from the extra columns of paths_planned 
x_t = pathN_points(:, 5);
y_t = pathN_points(:, 6);
z_t = pathN_points(:, 7);


%Distances  . . . will stay with N - 1 points regardless
delta_x = zeros(N, 1);
delta_y = delta_x;
delta_z = delta_x;
delta_xyz_f = delta_x;    %f is for looking forwards from current point
delta_xyz_b = zeros(N,1); %b is for looking backwards from current point

delta_x_Ry = zeros (N, 1);
delta_y_Ry = delta_x_Ry;
delta_z_Ry = delta_x_Ry;
curve_dist = 0;

%Slopes . . . stay with N - 1 points
Slope_xz = zeros(N, 1);
SlopeN_xz = Slope_xz;

Slope_yz = zeros(N, 1);
SlopeN_yz = Slope_yz;

%Angles
Theta_xz = zeros(N, 1);
Theta_yz = zeros(N, 1);

Rz = zeros(N, 1);
Ry = zeros(N, 1);
Rx = zeros(N, 1);


%Tool_pose: may add pts . . . bring up to N . . .
Tool_pose = zeros(N, 11);                         
Dia_disc = zeros(N, 1);
    %Retraction times . . .
    Retraction_time = 60*Retraction_dist/ext_speed_7;              
    Retraction_time_at_Prime_spd = 60*Retraction_dist/ext_speed_1;  
    %Tool_points associated with the UV-box . . .
    R_c01 = C_UVBox_Approach - C_noz_tip;                         
    R_c02 = C_UVBox_Target - C_noz_tip;                           
if Rank == 1        %Extrusion is horizontal
    Stoppage_delay = 0;
    Prime_time = 60*Prime_dist_flat/ext_speed_1; %Prime_time_flat  
else
    if Rank == 2            %Rank 2 (non-horizontal extrusion)
    Stoppage_delay =  Stoppage_delay_orig;
    Prime_time = 60*Prime_dist/ext_speed_1;
    
    else                    %Rank 3 applies
       Stoppage_delay =  Stoppage_delay_orig;
       Prime_time = 60*Prime_dist_off/ext_speed_1;
    end
end



%Work out pose of each "new tool":
for j = 1 : N                                     
    Rz(j) = 0;                                     
    delta_x(j) = x_t(j) - x_c(j);
    delta_y(j) = y_t(j) - y_c(j);
    delta_z(j) = z_t(j) - z_c(j);
    delta_xyz_f(j) = sqrt(delta_x(j)^2 + delta_y(j)^2 + delta_z(j)^2); 
    %To sort out the bug for a line parallel to y-axis
    if ((delta_x(j) == 0) && (delta_z(j) == 0))
        Ry(j) = 0;                                      
    else
        Slope_xz(j) = delta_z(j)/delta_x(j);
        SlopeN_xz(j) = -1/Slope_xz(j);          %Takes care of neg sign
        Theta_xz(j) = atan(Slope_xz(j));        %in rad
        Ry(j) = atan(delta_x(j)/delta_z(j));    %atan(SlopeN_xz(j));            
    end                                   
end

Lights_off_time = 60*Lights_off_dist/ext_speed_3;     
check1 = 0;
n_lightsoff = 0;                                     
curve_dist = 0;
%See n_lightsoff
for q = 1 : N - 1
    delta_xyz_b(q+1) = delta_xyz_f(q);            
    curve_dist = curve_dist + delta_xyz_b(q);     
    %Do check for n_lightsoff
    if check1 == 0
        if curve_dist >= Lights_off_dist
            n_lightsoff = q+1;
            check1 = 1;                     
        end
    end  
end
%Error check on delta_Ry: 
delta_Ry = zeros(N, 3);
%For use in Tool_start
checka = 0;   %on entering, a value has not yet been assigned to ts
ts_index = 0; %for index of point in toolpath where z_tool > z_approach
dist_covered = 0; 
%Calculate Rx:
for u = 1 : N                                                    
    x_Ry_current = x_c(u)*cos(Ry(u)) - z_c(u)*sin(Ry(u));                 
    y_Ry_current = y_c(u);
    z_Ry_current = x_c(u)*sin(Ry(u)) + z_c(u)*cos(Ry(u));
    
    
    x_Ry_next = x_t(u)*cos(Ry(u)) - z_t(u)*sin(Ry(u));                 
    y_Ry_next = y_t(u);
    z_Ry_next = x_t(u)*sin(Ry(u)) + z_t(u)*cos(Ry(u));
    
    delta_x_Ry(u) = x_Ry_next - x_Ry_current;                                     
    delta_y_Ry(u) = y_Ry_next - y_Ry_current;
    delta_z_Ry(u) = z_Ry_next - z_Ry_current;
 
    %Stick in storage for error checking purposes: 
        delta_Ry(u, 1) = delta_x_Ry(u);
        delta_Ry(u, 2) = delta_y_Ry(u);
        delta_Ry(u, 3) = delta_z_Ry(u);
    
    %Rx:
    %To sort out the bug for finding Rx for segments parallel
    %to x axis when Ry is forced to zero by inclination ctrl .
    
    if ((delta_y_Ry(u) == 0) && (delta_z_Ry(u) == 0))
        Rx(u) = 0;
    else
        Slope_yz(u) = delta_z_Ry(u)/delta_y_Ry(u);
        SlopeN_yz(u) = -1/Slope_yz(u);
        Theta_yz(u) = atan(Slope_yz(u)) ;                             
        Rx(u) = atan(SlopeN_yz(u));                                    
    end
    Tool_pose(u, 1) = pts_prev + u;                                      
    
    Tool_pose(u, 5) = Rx(u)*180/pi;
    Tool_pose(u, 6) = Ry(u)*180/pi;                    
    if abs(Ry(u)) == 0 || abs(Ry(u)) <= angle_lim*(pi/180)
        Tool_pose(u,6) = abs(Tool_pose(u,6));
    end
    Tool_pose(u, 7) = Rz(u)*180/pi;
    Tool_pose(u, 8) = 0;                                   
    if (Rank == 2) || (Rank == 3)            
    Nozzle_speed = ext_speed_3/60;
    else                   
    Nozzle_speed = ext_speed_4/60;
    end
        %Apply diameter filter for the upper and lower bounds 
        if d_c(u) < D_min
            d_c(u) = D_min;         %Apply the lower-bound filter
            Msg1 = ['Path ', num2str(path_position), ' point ',...
                num2str(u), ' was below lower threshold dia. ',...
                num2str(D_min), ' mm'];
            disp(Msg1)
        end
        
        if d_c(u) > D_max
            d_c(u) = D_max;         %Apply the upper bound filterf
            Msg2 = ['ERROR: Path ', num2str(path_position),...
                ' point ', num2str(u), ' was above upper threshold dia. ',...
                num2str(D_max), ' mm'];
            disp(Msg2)
        end
        
    
    v_tool = Nozzle_speed*(Nozzle_dia/d_c(u))^2;        
    v_tool_rounded = floor(v_tool*10)/10 ;
    
        %Calculate D_tool_rounded fpr feedback: 
        D_tool_rounded = sqrt((Nozzle_speed/v_tool_rounded)*Nozzle_dia^2);
        Dia_disc(u) = ((D_tool_rounded - d_c(u))/d_c(u))*100;      
    Tool_pose(u, 9) = v_tool_rounded;
    %Chuck the diameter values in as well for later plotting: 
    Tool_pose(u, 10) = pathN_points(u,4);
    Tool_pose(u, 11) = D_tool_rounded;
    x_Tool = Tool_bed(1) + x_c(u);                 
    y_Tool = Tool_bed(2) + y_c(u);
    z_Tool = Tool_bed(3) + z_c(u);
    Tool_pose(u, 2) = x_Tool;
    Tool_pose(u, 3) = y_Tool;
    if Rank == 1
        Tool_pose(u, 4) = z_Tool + z_offset_bed + z_raise_dist_flat;
        %ôverwrite the Tool_pose entry if the extrusion is flat . . .
    else 
        Tool_pose(u, 4) = z_Tool + z_offset_bed;                         
    end
 %Do a quick check for use in Start_tool (defined a bit later. . .  ) 
 
 
 
 
 if checka == 0   %Then we have not yet assigned a value 
     if u >= N - 1 %Then we cant go further with the dist_covered calc
         checka = 1;     
     else
     %Calculate the distance along the curve from the starting point: 
     dist_covered = dist_covered + sqrt((x_c(u+1) - x_c(u))^2 +...
         (y_c(u+1) - y_c(u))^2 + (z_c(u+1) - z_c(u))^2);
     end
     if dist_covered <= dist_approach
         ts_index = ts_index + 1;
     else 
         checka = 1;           
     end
 end 
end
if Rank == 1
Tool_start = [Tool_pose(1, 2), Tool_pose(1, 3), Tool_pose(1, 4) + z_approach, Tool_pose(1, 5), Tool_pose(1, 6), Tool_pose(1, 7), 0];
else   %(rank == 2 or rank == 3)
Tool_start = [Tool_pose(1, 2), Tool_pose(1, 3), Tool_pose(1, 4) + z_approach, Tool_pose(1, 5), Tool_pose(1, 6), Tool_pose(1, 7), 0];
end
%Define end tools
Tool_end_comb = zeros(4, 7);
%Only the end tools vary for horizontal / non-horizontal extrusions 
if (Rank == 2) || (Rank == 3)        
    %Compensation for setting distance: 
        %NOTE: EDITED WITHOUT TESTING (ROTATIONS MAY BE TO FAST)
    Tool_end_1 = [Tool_pose(N, 2), Tool_pose(N, 3), Tool_pose(N, 4) +...
        z_set_dist, Tool_pose(N, 5), Tool_pose(N, 6), Tool_pose(N, 7), 0];
    Tool_end_2 = [Tool_pose(N, 2), Tool_pose(N, 3), Tool_pose(N, 4) +...
        z_set_dist + z_wipe_dist, Tool_pose(N, 5), Tool_pose(N, 6),...
        Tool_pose(N, 7) + z_twist_angle, 0];        
    Tool_end_3 = [Tool_pose(N, 2), Tool_pose(N, 3), Tool_pose(N,4)+...
        z_wipe_dist + z_set_dist + z_rise_1, 0, 0, 0, 0];
    Tool_end_4 = [Tool_pose(N, 2), Tool_pose(N, 3), Tool_pose(N, 4) +...
        z_wipe_dist + z_set_dist + z_rise_2, 0, 0, 0, 0];
    
    
else   
    if path_position == No_horizontal_paths                                                                    
    Tool_end_1 = [Tool_pose(N, 2), Tool_pose(N, 3), Tool_pose(N, 4) +...
        z_drop_horiz, 0, 0, z_twist_angle, 0];      
    Tool_end_2 = Tool_bed - R_c01;    
    Tool_end_3 = Tool_bed - R_c02;           
    Tool_end_4 = Tool_bed - R_c01;  

    else                                
    Tool_end_1 = [Tool_pose(N, 2), Tool_pose(N, 3), Tool_pose(N, 4)...
        + 0.125*z_drop_horiz, 0, 0, 0, 0];
    Tool_end_2 = [Tool_pose(N, 2), Tool_pose(N, 3), Tool_pose(N, 4)...
        + 0.250*z_drop_horiz, 0, 0, 0, 0];
    Tool_end_3 = [Tool_pose(N, 2), Tool_pose(N, 3), Tool_pose(N, 4)...
        + 0.375*z_drop_horiz, 0, 0, 0, 0];
    Tool_end_4 = [Tool_pose(N, 2), Tool_pose(N, 3), Tool_pose(N, 4)...
        + 0.500*z_drop_horiz, 0, 0, 0, 0];
    end
end
%Combine the Tool_end vectors here:
for v = 1 : length(Tool_end_1)
    Tool_end_comb(1, v) = Tool_end_1(v);
    Tool_end_comb(2, v) = Tool_end_2(v);
    Tool_end_comb(3, v) = Tool_end_3(v);
    Tool_end_comb(4, v) = Tool_end_4(v);
    
end

end


