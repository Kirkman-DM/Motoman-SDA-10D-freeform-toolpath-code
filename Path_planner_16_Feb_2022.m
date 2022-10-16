function [Paths_planned, Paths_splitup_Reorg, Number_of_paths, N_rows_per_path_post, THETA_out, TCP_offset, NTP_angles] = Path_planner_16_Feb_2022(XL_filename,...
    z_hgt_max, lin_lim, incl, Inclination, Coll_avoid, search_rad, nozzle_clearance, phi_increment, phi_slim, Ranking, relax_index_length, Nozzle_dia, Bead_dia, theta_manual_control, phi_manual_control, z_corr)


%LOCAL PARAMETERS:
Noz_length_imag = 10;    %imaginary nozzle length used in finding NTP positions


%GEOMETRY POINT FETCHING
path_points_ALL = xlsread(XL_filename);
%Now we have captured ALL of the populated cells in the excel file
%Need to figure out how many extrusion paths there are
EXL_width = numel(path_points_ALL(1, :));          %Read how many entries are in the first row
Number_of_paths = EXL_width/5;                     %Are 5 columns for each extrusion (incl. phi and theta)

%Save points into an array for use in the respective functions:
N_row_real = zeros(EXL_width, 1);           %Number of real rows that have been imported
N_max = numel(path_points_ALL(:,1));        %Automatically give max nr of columns . . . but the real number for each ath may be less due to Nan values which are removed below
%Remove NaN entries so that toolpaths can have varying lengths
for e = 1 :  EXL_width     %Each column, one at a time
    for f = 1 :  N_max     %Each row, one at a time, within each column
        if isnan(path_points_ALL(f,e)) == 0     %Then the entry is NOT NaN
            N_row_real(e) = N_row_real(e) + 1;  %And we increase N by 1 since the current row has a real entry . . .
        end
    end
    
end
%We have now checked the length of each toolpath and stored it in the N array
%NOTE: We are using ALL the values for this. Size of N is equal to number of columns

%Create a storage array for each toolpath:
Points_imported = zeros(N_max, EXL_width);              %The actual columns may not reach the end of this matrix
%Populate this array:
for b_mag = 1 : EXL_width                                   %The columns, one at a time
    for c = 1 : N_row_real(b_mag)                           %The rows, one at a time, for each column:
        Points_imported(c, b_mag) = path_points_ALL(c,b_mag);   %There are now zeroes where the NaN values were
    end
end
%Now get an array that is the stripped down version of N_row_real(delete all the repeated columns):
N_rows_per_path_pre = zeros(Number_of_paths, 1);        %Number of rows per path before reorganising.
for t = 1 : Number_of_paths
    N_rows_per_path_pre(t) = N_row_real(5*t);           %Checking using the theta col
end

%Array for imported points: Still keeps zeros
%This could be replaced with a cell array to simplify process further.
Points_imported_corrected = zeros(N_max, EXL_width);                    %Again, this is the size of the whole "excel square" with extra zeroes and all . . .
%Above still accommodates for the extra diameter column . . .


%Flip the path upside down if necessary
for s = 1 : Number_of_paths
    if Points_imported(1, 5*s - 2) > Points_imported(N_rows_per_path_pre(s), 5*s - 2)
        %NOTE: we are ignoring the last zeroes
        for  g = (5*s-4) : 5*s
            for f = 1 : N_rows_per_path_pre(s)
                Points_imported_corrected(f,g) = Points_imported(N_rows_per_path_pre(s) - f + 1, g);
            end
        end
    else
        for  g = (5*s-4) : 5*s
            for f = 1 : N_rows_per_path_pre(s)
                Points_imported_corrected(f,g) = Points_imported(f, g);
            end
        end
    end
end

%PATH RANKING

%Split points_imported_corrected into a cell array:
Paths_splitup = cell(Number_of_paths,1);
Paths_splitup_Reorg = cell(Number_of_paths,1);
Path_rank_1 = zeros(Number_of_paths, 1);
NTP_angles = cell(Number_of_paths, 1);

for g = 1 : Number_of_paths
    Paths_splitup(g) = {Points_imported_corrected((1:N_rows_per_path_pre(g)), ((5*g-4):5*g))};
    current_path = Paths_splitup{g};
    if (current_path(length(current_path), 3) <= z_hgt_max)   %sorting has been done already so last point is the highest. Assumes unimodal
        Path_rank_1(g) = 1;
    else %Not flat but still starts on the bed
        if (current_path(1, 3) <= z_hgt_max) && (current_path(length(current_path), 3) > z_hgt_max)  %Extrusion starts on the bed and is not flat
            Path_rank_1(g) = 2;
        else %Not rank 1 or 2. Ie the path starts above the bed
            Path_rank_1(g) = 3;
            disp('Rank 3 has been allocated')
        end
    end
end


Paths_splitup_Reorg = Paths_splitup;            %Remove the redundance if time later . . .





%Do the z adjustment to ensure that the lowest point on the extrusion is shiftd to z = 0
if strcmp(z_corr, 'ON') == 1        %If z correction is enabled
    %Find the absolute minimum z point with which to adjust all of the others
    minZ = zeros(1, Number_of_paths);
    for v = 1 : Number_of_paths
        minZ(v) = min(Paths_splitup_Reorg{v}(:, 3));
    end
    minZ_fin = min(minZ);       %Absolute lowest Z value
    
    %Then adjust all the other z values using this entry
    for h = 1 : Number_of_paths
        
        Paths_splitup_Reorg{h}(:, 3) = Paths_splitup_Reorg{h}(:, 3) - minZ_fin;     %Goes to zero if minZ is either +ve or -ve . . .
        
    end
end


%Find the number of rows per path for the rearranged version:
N_rows_per_path_post = zeros(Number_of_paths, 1);

for q = 1 : Number_of_paths
    N_rows_per_path_post(q) = numel(Paths_splitup_Reorg{q}(:,1));
end


%TOOLPATH GENERATION LOOP

%//////////////////////////////////////////////////////////////////////////
%Inclination control and collision avoidance: using tool definitions
%For storage / initialization:

THETA_out = cell(Number_of_paths, 1);
Paths_planned = cell(Number_of_paths, 1);
TCP_offset = cell(Number_of_paths, 1);

for k = 1 : Number_of_paths
    
    %Find nozzle orientations within each path within the k loop
    for m = 1 : length(Paths_splitup_Reorg{k}(:,1))
        %Step 1: find phi and theta_orig (angle of each segment above the horizontal)
        %Current points:
        x_cur =  Paths_splitup_Reorg{k}(m, 1);
        y_cur =  Paths_splitup_Reorg{k}(m, 2);
        z_cur =  Paths_splitup_Reorg{k}(m, 3);
        
        theta_out = Paths_splitup_Reorg{k}(m, 5);           %Change the output theta to the manually prescribed value
        phi_inc = Paths_splitup_Reorg{k}(m, 4);             %Change the output theta to the manually prescribed value
        
        NTP_angles{k}(m, 1) = phi_inc;
        NTP_angles{k}(m, 2) = phi_inc*180/pi;
        NTP_angles{k}(m, 3) = theta_out;
        NTP_angles{k}(m, 4) = theta_out*180/pi;
        
        %Store PHI_inc before any collision avoidance is applied to check what changes collision avoidance has made
        PHI_inc{k}(m,1) = phi_inc;
        PHI_inc_coll_a{k}(m,1) = phi_inc; %These will be over-rided if there is relaxation
        %Store Theta:
        THETA_out{k}(m,1) = theta_out;
        
        %Now we need to find the new coordinates of the NTP
        %use the fixed nozzle length as the delta value, then use phi and theta_orig to find delta(x, y, z)
        
        del_x_NTP = Noz_length_imag*sin(phi_inc)*cos(theta_out);
        del_y_NTP = Noz_length_imag*sin(phi_inc)*sin(theta_out);
        del_z_NTP = Noz_length_imag*cos(phi_inc);
        
        %Get next values from current values using deltas
        x_NTP = x_cur + del_x_NTP;                %ALL of the *next* values have the amplification factor included
        y_NTP = y_cur + del_y_NTP;
        z_NTP = z_cur + del_z_NTP;
        
        if m == 1       %To be used later in the TCP offsets for the first point 
            m_1_NTP_x = x_NTP;
            m_1_NTP_y = y_NTP;
            m_1_NTP_z = z_NTP;
        end
        
        %/////////////////////////TCP OFFSET . . . /////////////////////
        
        %NOW we apply the TCP offset to make sure the nozzle tip follows the correct path even when inclination control is applied (no gouging)
        %Will need to do the last TCP' on the outside of this loop  . . .
        %See writeup to get variables  . . .
        
        
        
        TCP_unadj = [x_cur y_cur z_cur];                %Our TCP position before adjustment
        NTP_unadj = [x_NTP y_NTP z_NTP];                %The NTP doesn't need adjustment
                    
        if m > 1  %from the second point to the last point 
            
            PRV_pt = [Paths_splitup_Reorg{k}(m-1,1) Paths_splitup_Reorg{k}(m-1,2) Paths_splitup_Reorg{k}(m-1,3)];
            
            T = NTP_unadj - TCP_unadj;
            b = NTP_unadj - PRV_pt;
            E_par = TCP_unadj - PRV_pt;
            
            T_mag = norm(T);
            b_mag = norm(b);
            E_par_mag = norm(E_par);
            
            %Find beta using cosine rule:
            beta = acos((T_mag^2 + E_par_mag^2 - b_mag^2)/(2*T_mag*E_par_mag));
            omega = beta - pi/2;
            
            if beta ~= pi           %Then the extrusion is not vertical . . . 
                
                %Find e using nozzle diameter and omega:
                e = Nozzle_dia*sin(omega)/2;
                
                %Find offset d using e and extrusion bead diameter:
                d = Bead_dia/2 - e;
                %Filter for plotting:
                
                TCP_offset{k}(m) = d;       %For plotting purposes . . . 
                %Use Rodrigues rotation formula to find E_perp_u unit vector
                %Find kr (perp unit vector about which to rotate):
                CP = cross(E_par, T);
                kr = CP/norm(CP);
                
                %Execute the rotation:
                E_perp = T*cos(omega) + cross(kr, T)*sin(omega);     %We left out the last term since the dot product would equate to zero
                E_perp_u = E_perp/norm(E_perp);
                
                if m == 2 %(we need this value for the m == 1 case later . . .
                   TCP_offset{k}(1) = d; 
                   m_1_perp_u = E_perp_u;     %will be overidden for each k value . . .  
                end
                
                %Now, adjust the unadjusted TCP and NTP values in the direction of E_perp_u:
                TCP_adj = TCP_unadj + d*E_perp_u;
                NTP_adj = NTP_unadj + d*E_perp_u;
                
            else    %Our T vector is parallel to E_par 
                %The nozzle is parallel to the extrusion and no offset is required
                TCP_adj = TCP_unadj;
                NTP_adj = NTP_unadj;
                d = 0;                  %Ensures that no adjustment is applied to the final entries as below.
                TCP_offset{k}(m) = 0;
                E_perp_u = [0 0 0];
                
                if m == 2 %(we need this value for the m == 1 case later . . .
                   TCP_offset{k}(1) = d; 
                   m_1_perp_u = E_perp_u;     %will be overidden for each k value . . .  
                end
            end
        %Still assuming m > 1
        Paths_planned{k}(m, 1) = TCP_adj(1);
        Paths_planned{k}(m, 2) = TCP_adj(2);
        Paths_planned{k}(m, 3) = TCP_adj(3);
        Paths_planned{k}(m, 4) = Paths_splitup_Reorg{k}(m, 4); %diameter
        Paths_planned{k}(m, 5) = NTP_adj(1);
        Paths_planned{k}(m, 6) = NTP_adj(2);
        Paths_planned{k}(m, 7) = NTP_adj(3); 
        
        else        %For the m == 1 case . . . no TCP offset applied for now. . . to be over-ridden later se could eliminate this . . . 
        Paths_planned{k}(m, 1) = TCP_unadj(1);
        Paths_planned{k}(m, 2) = TCP_unadj(2);
        Paths_planned{k}(m, 3) = TCP_unadj(3);
        Paths_planned{k}(m, 4) = Paths_splitup_Reorg{k}(m, 4); %diameter
        Paths_planned{k}(m, 5) = NTP_unadj(1);
        Paths_planned{k}(m, 6) = NTP_unadj(2);
        Paths_planned{k}(m, 7) = NTP_unadj(3);   
        end
        
%         if m < length(Paths_splitup_Reorg{k}(:,1))
%             NXT_pt = [Paths_splitup_Reorg{k}(m+1,1) Paths_splitup_Reorg{k}(m+1,2) Paths_splitup_Reorg{k}(m+1,3)];
%             
%             T = NTP_unadj - TCP_unadj;
%             b = NTP_unadj - NXT_pt;
%             E_par = NXT_pt - TCP_unadj;
%             
%             T_mag = norm(T);
%             b_mag = norm(b);
%             E_par_mag = norm(E_par);
%             
%         
%             
%             %Find beta using cosine rule:
%             beta = acos((T_mag^2 + E_par_mag^2 - b_mag^2)/(2*T_mag*E_par_mag));
%             omega = pi/2 - beta;
%             
%             if beta ~= 0
%                 %Find e using nozzle diameter and omega:
%                 e = Nozzle_dia*sin(omega)/2;
%                 
%                 %Find offset d using e and extrusion bead diameter:
%                 d = Bead_dia/2 - e;
%                 %Filter for plotting:
%                 
%                 TCP_offset{k}(m) = d;
%                 %Use Rodrigues rotation formula to find E_perp_u unit vector
%                 %Find kr (perp unit vector about which to rotate):
%                 CP = cross(E_par, T);
%                 kr = CP/norm(CP);
%                 
%                 %Execute the rotation:
%                 E_perp = T*cos(omega) + cross(kr, T)*sin(omega);     %We left out the last term since the dot product would equate to zero
%                 E_perp_u = E_perp/norm(E_perp);
%                 
%                 %Now, adjust the unadjusted TCP and NTP values in the direction of E_perp_u:
%                 TCP_adj = TCP_unadj + d*E_perp_u;
%                 NTP_adj = NTP_unadj + d*E_perp_u;
%                 
%             else %The nozzle is parallel to the extrusion and no offset is required
%                 TCP_adj = TCP_unadj;
%                 NTP_adj = NTP_unadj;
%                 d = 0;                  %Ensures that no adjustment is applied to the final entries as below.
%                 TCP_offset{k}(m) = 0;
%                 E_perp_u = [0 0 0];
%             end
%             
%         else                %We are on the last point and dont have a next point to use . . . use the definitions from the second last point . . .
%             if beta ~= 0
%                 TCP_adj = TCP_unadj + d*E_perp_u;
%                 NTP_adj = NTP_unadj + d*E_perp_u;          
%             else
%                 TCP_adj = TCP_unadj;
%                 NTP_adj = NTP_unadj;
%             end
%             
%         end
     
    end
   %Now do the TCP offset for the point m == 1 . . . (this is done once for each (k) path)
   TCP_adj_M_1 = TCP_offset{k}(1)*m_1_perp_u;
   Paths_planned{k}(1, 1) = Paths_splitup_Reorg{k}(1, 1) + TCP_adj_M_1(1);   %Current point + offset in the correct direction 
   Paths_planned{k}(1, 2) = Paths_splitup_Reorg{k}(1, 2) + TCP_adj_M_1(2);
   Paths_planned{k}(1, 3) = Paths_splitup_Reorg{k}(1, 3) + TCP_adj_M_1(3);
   Paths_planned{k}(1, 4) = Paths_splitup_Reorg{k}(m, 4);                                 %diameter
   
   NTP_adj_M_1 = TCP_offset{k}(1)*m_1_perp_u;
   Paths_planned{k}(1, 5) = m_1_NTP_x + NTP_adj_M_1(1);
   Paths_planned{k}(1, 6) = m_1_NTP_y + NTP_adj_M_1(2);
   Paths_planned{k}(1, 7) = m_1_NTP_z + NTP_adj_M_1(3);
end
disp('     ');
end