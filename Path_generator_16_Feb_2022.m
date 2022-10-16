function [Tool_pose, Stoppage_delay, Tool_end_comb,Tool_start, Rx, Ry, delta_Ry] = Path_generator_16_Feb_2022(Re,pathN_points, N, N_rows_per_path, Number_of_paths,...
    path_position, Tool_speed,z_offset_bed, z_end_dist, z_raise_dist_flat, bump_dist, lin_lim, zero_lim, z_hgt_max, set_dist, cut_offset, fib_protrusion_dist,...
    C_noz_tip, C_UVBox_Target, C_UVBox_Approach, Tool_bed, angle_lim, Stoppage_delay_orig, pts_prev, z_drop_horiz, dist_approach, z_rise_postcut,...
    Nozzle_dia, z_smear, xy_smear, NTP_angles, start_tool_sign)

%NOTE: pathNpoints is not from paths_planned NOT paths_splitup
%//Storage///////////////////////////////////////////////////////////////////////////////
%NOTE: N_rows_per_path became N

%Extract the *current/TCP* points from paths_planned
    %These points correspond to the TCP points for the tool definition 
x_c = pathN_points(:, 1);                        %x, y, z values imported from excel file
y_c = pathN_points(:, 2);
z_c = pathN_points(:, 3);
d_c = pathN_points(:, 4);                        %Imported diameter 
N = numel(z_c);
N_lim = N;

%Extract the *tool direction/NTP* points from the extra columns of paths_planned 
x_t = pathN_points(:, 5);
y_t = pathN_points(:, 6);
z_t = pathN_points(:, 7);


%Distances  . . . will stay with N - 1 points regardless
delta_x = zeros(N, 1);
delta_y = delta_x;
delta_z = delta_x;
delta_xyz_f = delta_x;                                %f is for looking forwards . . . from current point
delta_xyz_b = zeros(N,1);                             %b is for looking backwards . . . from current point

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
Tool_pose = zeros(N, 10);                           %Expl: Index, x, y, z, Rx, Ry, Rz, Re, Speed, Dia_in, Dia_out
%//^^Storage^^/////////////////////////////////////////////////////////////

%Pre - Calculations (SHOULD BE IN MAIN SCRIPT OTHERWISE THEY ARE CALLED MULTIPLE TIMES . . .)

    %Tool_points associated with the UV-box . . .
    R_c01 = C_UVBox_Approach - C_noz_tip;                         %Vector from noz tip to approach point
    R_c02 = C_UVBox_Target - C_noz_tip;                           %Vector from noz tip to UV box 
   
%///////////////////////////

%Check Rank and decide on toolpath parameters
    %stoppage delay used to indicate rank? 

       Stoppage_delay =  Stoppage_delay_orig;


%Work out pose of each "new tool":
for j = 1 : N                                     
    Rz(j) = 0;                                     %Assume the y-axis of each new "tool" always lies in the z-y plane (may need to review this assumption . . .
    %OR IS IT??? May have to use Rz = -90 deg for im not sure what . ..
    %the 90 deg is just to aligh the robot axis with the tool axis?
    
    %Delta's: in terms of bed coordinates which are simply a translated version of flange coordinates . . .
    
    delta_x(j) = x_t(j) - x_c(j);
    delta_y(j) = y_t(j) - y_c(j);
    delta_z(j) = z_t(j) - z_c(j);
    delta_xyz_f(j) = sqrt(delta_x(j)^2 + delta_y(j)^2 + delta_z(j)^2); %The distance from the current point to the next point (forward distance) (does NOT accumulate) ;

    %To sort out the bug for a line parallel to y-axis
    if ((delta_x(j) == 0) && (delta_z(j) == 0))
        Ry(j) = 0;                                      %We will line up the z axes using Rx . . .
    else
        Slope_xz(j) = delta_z(j)/delta_x(j);
        SlopeN_xz(j) = -1/Slope_xz(j);              %Takes care of neg sign
        Theta_xz(j) = atan(Slope_xz(j));            %in rad
        Ry(j) = atan(delta_x(j)/delta_z(j));       %atan(SlopeN_xz(j));            
    end                                   
end


%Error check on delta_Ry: 
delta_Ry = zeros(N, 3);
%For use in Tool_start
checka = 0;   %on entering, a value has not yet been assigned to ts
ts_index = 0; %for index of point in toolpath where z_tool > z_smear
dist_covered = 0; %to check how far we are along the extrusion when defining the start tool 


%Calculate Rx:
for u = 1 : N                                                    
    %Calculate the position of the tool relative to the rotated coordinate system
    %NOTE: the transformation applied is for a coordinate system and not a
    %vector  . . . the matrices used are the inverse of those used for a
    %vector rotation.
    %Right hand rule applies
    %Ry made negative due to the axes being in the "wrong" direction.
    
    x_Ry_current = x_c(u)*cos(Ry(u)) - z_c(u)*sin(Ry(u));                  %Takes into accountthe sign of Ry . . .
    y_Ry_current = y_c(u);
    z_Ry_current = x_c(u)*sin(Ry(u)) + z_c(u)*cos(Ry(u));
    
    
    x_Ry_next = x_t(u)*cos(Ry(u)) - z_t(u)*sin(Ry(u));                  %Use the same Ry as before . . .
    y_Ry_next = y_t(u);
    z_Ry_next = x_t(u)*sin(Ry(u)) + z_t(u)*cos(Ry(u));
    
    delta_x_Ry(u) = x_Ry_next - x_Ry_current;                                      %Use angles with inclination control applied . . .
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
        Theta_yz(u) = atan(Slope_yz(u)) ;                              %in rad
        Rx(u) = atan(SlopeN_yz(u));                                    %in rad
    end
    
    %Populate tool_pose arrays:
    Tool_pose(u, 1) = pts_prev + u;                                       %Index
    
    Tool_pose(u, 5) = Rx(u)*180/pi;
    Tool_pose(u, 6) = Ry(u)*180/pi;                      %NOTE THE MINUS: Robot: even y rotation is +ve for ccw looking down axis
    %Force val to zero if below a limit (rounding etc . . .)
    %Have to put loop here otherwise we end up with value -0.00000 . . .
    if abs(Ry(u)) == 0 || abs(Ry(u)) <= angle_lim*(pi/180)
        Tool_pose(u,6) = abs(Tool_pose(u,6));
    end
    
    Tool_pose(u, 7) = Rz(u)*180/pi;
    Tool_pose(u, 8) = Re;                                       %Re
    
    
    
    %determine v_tool to accomplish the desired diameter . . .
    Tool_pose(u, 9) = Tool_speed;
    %Chuck the diameter values in as well for later plotting: 
    Tool_pose(u, 10) = pathN_points(u,4);
    %NOTE: Tool_pose_ALL(:, 10) contains the input diameter from the
   
    %Find the position of the new tool tip **relative to the flange** for each iteration:
    %NOTE: the bed and the wrist flange rotate together.
    x_Tool = Tool_bed(1) + x_c(u);                  %Still use the *current* point to define TCP positions 
    y_Tool = Tool_bed(2) + y_c(u);
    z_Tool = Tool_bed(3) + z_c(u);
    
 
    Tool_pose(u, 2) = x_Tool;
    Tool_pose(u, 3) = y_Tool;
    
    %if the extrusion is horizontal then the tool needs to be raised a bit. . . applied below:
    
    
        Tool_pose(u, 4) = z_Tool + z_offset_bed;                         %Note z offset bed distance is applied here . . .

 %Do a quick check for use in Start_tool (defined a bit later. . .  ) 
  
 if checka == 0   %Then we have not yet assigned a value 
     if u >= N - 1 %Then we cant go further with the dist_covered calc
         checka = 1;
         %and we will be using the ts_index calculated in the previous iteration
     else
     %Calculate the distance along the curve from the starting point: 
     dist_covered = dist_covered + sqrt((x_c(u+1) - x_c(u))^2 + (y_c(u+1) - y_c(u))^2 + (z_c(u+1) - z_c(u))^2);
     end
     
     
     if dist_covered <= dist_approach %Then we have not yet reached our desired index . . .     
         ts_index = ts_index + 1;
     else %z_tool has reached z_smear and the final value has been assigned 
         checka = 1;            %We will no longer enter the first if loop
     end
 end
 
    
end

%Define the start tool: (WE IDEALLY NEED AN EXTRA START TOOL BEFORE THIS)
    %Start by finding the direction from the origin to the start point of the extrusion. 


start_u = start_tool_sign*[cos(NTP_angles(1, 3)), sin(NTP_angles(1, 3)), 0];   %Note that the NTP angles thing has the degree cols as well (ie third col for theta rad) 

    %Then specify the start tool: offset in the start_u direction by xy_smear and upwards by z_smear
Tool_start = [Tool_pose(1, 2) + xy_smear*start_u(1), Tool_pose(1, 3) + xy_smear*start_u(2), Tool_pose(1, 4) + z_smear, Tool_pose(1, 5), Tool_pose(1, 6), Tool_pose(1, 7), Re];
%%NOTE^^ above had pose of zero for normal extrusion, not mech testing 

    %We should ideally use "centroid" of part and not origin for this
    %won't work very well if part is not centered around origin 



%Define end tools
Tool_end_comb = zeros(4, 7);
%Calculate the final unit vector for applying the offsets: 
path_direc = [x_c(N) - x_c(N-1), y_c(N) - y_c(N-1), z_c(N) - z_c(N-1)];
path_unit = path_direc/norm(path_direc);

noz_direc = [x_t(N) - x_c(N), y_t(N) - y_c(N), z_t(N) - z_c(N)];
noz_unit = noz_direc/norm(noz_direc);

%Only the end tools vary for horizontal / non-horizontal extrusions . . .
    %Compensation for setting distance: 
    Tool_end_1 = [Tool_pose(N, 2) + set_dist*path_unit(1), Tool_pose(N, 3) + set_dist*path_unit(2), Tool_pose(N, 4) + set_dist*path_unit(3), Tool_pose(N, 5), Tool_pose(N, 6), Tool_pose(N, 7), Re];    %Let the nozzle go a further z_set_dist. Keep the same tilt 
    if cut_offset == 0
    Tool_end_2 = Tool_end_1;
    else
    Tool_end_2 = [Tool_pose(N, 2)+ cut_offset*noz_unit(1), Tool_pose(N, 3) + cut_offset*noz_unit(2), Tool_pose(N, 4) + cut_offset*noz_unit(3),Tool_pose(N, 5), Tool_pose(N, 6), Tool_pose(N, 7), Re];    
    end
    Tool_end_3 = [Tool_pose(N, 2) + (cut_offset + fib_protrusion_dist)*noz_unit(1), Tool_pose(N, 3) + (cut_offset + fib_protrusion_dist)*noz_unit(2), Tool_pose(N, 4) + (cut_offset + fib_protrusion_dist )*noz_unit(3), Tool_pose(N, 5), Tool_pose(N, 6), Tool_pose(N, 7), Re];
    Tool_end_4 = [Tool_end_3(1), Tool_end_3(2), Tool_end_3(3) + z_rise_postcut, Tool_pose(N, 5), Tool_pose(N, 6), Tool_pose(N, 7), Re]; %We simply added z_rise_postcut to the last end tool
    
    
    %The above is an updated version of the below: 
    %Tool_end_2 = [Tool_end_1(1)+ cut_offset*noz_unit(1), Tool_end_1(2) + cut_offset*noz_unit(2), Tool_end_1(3) + cut_offset*noz_unit(3),Tool_pose(N, 5), Tool_pose(N, 6), Tool_pose(N, 7), 0];  
    %Tool_end_3 = [Tool_end_2(1) + (fib_protrusion_dist - set_dist)*noz_unit(1), Tool_end_2(2) + (fib_protrusion_dist - set_dist)*noz_unit(2), Tool_end_2(3) + (fib_protrusion_dist - set_dist)*noz_unit(3), Tool_pose(N, 5), Tool_pose(N, 6), Tool_pose(N, 7), 0];
    %Tool_end_4 = [Tool_end_3(1), Tool_end_3(2), Tool_end_3(3) + z_rise_postcut, 0, 0, 0, 0]; %We simply added z_rise_postcut to the last end tool
    
    

%Combine the Tool_end vectors here:
for v = 1 : length(Tool_end_1)
    Tool_end_comb(1, v) = Tool_end_1(v);
    Tool_end_comb(2, v) = Tool_end_2(v);
    Tool_end_comb(3, v) = Tool_end_3(v);
    Tool_end_comb(4, v) = Tool_end_4(v);
    
end

end


