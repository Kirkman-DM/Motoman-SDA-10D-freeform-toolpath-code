function [Paths_planned, Paths_splitup_Reorg, Sorted_rank,...
    Number_of_paths, No_horizontal_paths, N_rows_per_path_post,...
    PHI, THETA, PHI_inc,PHI_inc_coll_a, PHI_inc_coll, THETA_inc,...
    xy_check, coll_cell] = Path_planner_25_May_2020(XL_filename,...
    z_hgt_max, lin_lim,incl, Inclination, search_rad,...
    nozzle_clearance, phi_increment, phi_slim, Ranking, relax_index_length)

%LOCAL PARAMETERS:
Noz_length_imag = 1; %imaginary nozzle length used in finding NTP positions

%GEOMETRY POINT FETCHING
path_points_ALL = xlsread(XL_filename);
EXL_width = numel(path_points_ALL(1, :));
Number_of_paths = EXL_width/4;

%Save points into an array for use in the respective functions:
N_row_real = zeros(EXL_width, 1);
N_max = numel(path_points_ALL(:,1));
%Remove NaN entries
for e = 1 :  EXL_width     %Each column, one at a time
    for f = 1 :  N_max     %Each row, one at a time, within each column
        if isnan(path_points_ALL(f,e)) == 0     %Then the entry is NOT NaN
            N_row_real(e) = N_row_real(e) + 1;
            %^And we increase N by 1 since the current row has a real entry
        end
    end
    
end
%We have checked the length of each toolpath and stored it in the N array
%We are using ALL the values for this. Size of N equals number of columns

%Create a storage array for each toolpath:
Points_imported = zeros(N_max, EXL_width);
%^The actual columns may not reach the end of this matrix

for b = 1 : EXL_width
    for c = 1 : N_row_real(b)
        Points_imported(c, b) = path_points_ALL(c,b);
    end
end
%Now get an array that is the stripped down version of N_row_real
N_rows_per_path_pre = zeros(Number_of_paths, 1);
for t = 1 : Number_of_paths
    N_rows_per_path_pre(t) = N_row_real(4*t);
end

%Array for imported points: Still keeps zeros
Points_imported_corrected = zeros(N_max, EXL_width);
%Above still accommodates for the extra diameter column

for s = 1 : Number_of_paths
    if Points_imported(1, 4*s - 1) >...
            Points_imported(N_rows_per_path_pre(s), 4*s - 1)
        for  g = (4*s-3) : 4*s
            for f = 1 : N_rows_per_path_pre(s)
                Points_imported_corrected(f,g) =...
                    Points_imported(N_rows_per_path_pre(s) - f + 1, g);
            end
        end
    else
        for  g = (4*s-3) : 4*s
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

for g = 1 : Number_of_paths
    Paths_splitup(g) = {Points_imported_corrected((1:N_rows_per_path_pre(g)),((4*g-3):4*g))};
    current_path = Paths_splitup{g};
    if (current_path(length(current_path), 3) <= z_hgt_max)
        Path_rank_1(g) = 1;
    else %Not flat but still starts on the bed
        if (current_path(1, 3) <= z_hgt_max) && ...
                (current_path(length(current_path), 3) > z_hgt_max)
            Path_rank_1(g) = 2;
        else %Not rank 1 or 2. Ie the path starts above the bed
            Path_rank_1(g) = 3;
        end
    end
end

%Reorganize paths based on their ranks:
Sorted_rank = sort(Path_rank_1);
assign_check = zeros(Number_of_paths, 1);

%If path reorganization set to AUTO, then reorganize here:
if strcmp(Ranking, 'AUTO') == 1
    for r = 1 : Number_of_paths
        t = 1;
        while t <= Number_of_paths
            if assign_check(t,1) == 1
                t = t + 1;
            else
                if Sorted_rank(r) == Path_rank_1(t)
                    Paths_splitup_Reorg(r) = Paths_splitup(t);
                    assign_check(t,1) = 1;
                    t = Number_of_paths + 1;
                else
                    t = t + 1;
                end
            end
        end
    end
else %if path reorganization is set to manual
    for y = 1 : Number_of_paths
        Paths_splitup_Reorg(y) = Paths_splitup(y);
    end
end

%Check for how may horizontal extrusions there are
No_horizontal_paths = 0;
for p = 1 : length(Sorted_rank)
    if Sorted_rank(p) == 1
        No_horizontal_paths  = No_horizontal_paths + 1;
    end
end

%Find the number of rows per path for the rearranged version:
N_rows_per_path_post = zeros(Number_of_paths, 1);

for q = 1 : Number_of_paths
    N_rows_per_path_post(q) = numel(Paths_splitup_Reorg{q}(:,1));
end

%TOOLPATH GENERATION LOOP
%////////////////////////////////////////////////////////////////////////
%Inclination control and collision avoidance: using tool definitions
%For storage / initialization:
PHI = cell(Number_of_paths, 1);
PHI_inc = cell(Number_of_paths, 1);
PHI_inc_coll_a = cell(Number_of_paths, 1);
PHI_inc_coll = cell(Number_of_paths, 1);
THETA = cell(Number_of_paths, 1);
THETA_inc = cell(Number_of_paths, 1);
Paths_planned = cell(Number_of_paths, 1);
ANGLES_INC = zeros(Number_of_paths,2);
xy_check  = cell(Number_of_paths, 1);
Nr_paths_into_non_horizontal = 0;
End_coll = 0;
flag_index = 0;
coll_cell = cell(Number_of_paths, 1);
coll_cell_sorted = cell(Number_of_paths, 1);

for k = 1 : Number_of_paths
    %COLLISION IDENTIFICATION
    %Initiate variables
    number_of_collisions = 0;
    coll_cell{k} = 0;
    
    if Sorted_rank(k) >= 2
        Nr_paths_into_non_horizontal = Nr_paths_into_non_horizontal + 1;
        if Nr_paths_into_non_horizontal >= 2
            
            %Find the endpoints of the current path:
            x_end_current = Paths_splitup_Reorg{k}...
                (length(Paths_splitup_Reorg{k}(:, 1)), 1);
            y_end_current = Paths_splitup_Reorg{k}...
                (length(Paths_splitup_Reorg{k}(:, 1)), 2);
            z_end_current = Paths_splitup_Reorg{k}...
                (length(Paths_splitup_Reorg{k}(:, 1)), 3);
            
            
            for c = (No_horizontal_paths + 1) : k - 1
                x_end_prev = Paths_splitup_Reorg{c}...
                    (length(Paths_splitup_Reorg{c}(:, 1)), 1);
                y_end_prev = Paths_splitup_Reorg{c}...
                (length(Paths_splitup_Reorg{c}(:, 1)), 2);
                z_end_prev = Paths_splitup_Reorg{c}...
                    (length(Paths_splitup_Reorg{c}(:, 1)), 3);
                %Calc dist between current point and previous point:
                dist_coll_end = sqrt((x_end_current - x_end_prev)^2 +...
                    (y_end_current - y_end_prev)^2+(z_end_current - z_end_prev)^2);
                %Check if dist falls within search radius
                if dist_coll_end <= search_rad
                    number_of_collisions = number_of_collisions + 1;
                    coll_cell{k}(number_of_collisions, 1) = c;
                    coll_cell{k}(number_of_collisions, 2) = x_end_current;
                    coll_cell{k}(number_of_collisions, 3) = y_end_current;
                    coll_cell{k}(number_of_collisions, 4) = z_end_current;
                    coll_cell{k}(number_of_collisions, 5) =...
                        length(Paths_splitup_Reorg{k}(:,1));
                    
                else
                    
                    if z_end_current - z_end_prev > 0
                        checking_point = [x_end_prev, y_end_prev, z_end_prev];
                        path_to_check = k;
                        mes10 = ['Path ', num2str(k),...
                            ' ends higher than path ', num2str(c)];
                        disp(mes10)
                        mes11 = ['Path to check is path ', num2str(k),...
                            ' using the endpoint of path ', num2str(c)];
                        disp(mes11)
                    else
                        checking_point = [x_end_current, y_end_current,...
                            z_end_current];
                        path_to_check = c;
                        mes10 = ['Path ', num2str(k), ' ends lower than path ', num2str(c)];
                        disp(mes10)
                        mes11 = ['Path to check is path ', num2str(c),...
                            ' using the endpoint of path ', num2str(k)];
                        disp(mes11)
                    end
                    
                    coll_check_1 = 0;
                    h = 1;   %Initialize the counter for the while loop
                    while (coll_check_1 == 0) && (h <=...
                            length(Paths_splitup_Reorg{path_to_check}(: , 1)) - 1)
                   
                        x_mid_path = Paths_splitup_Reorg{path_to_check}(h, 1);
                        y_mid_path = Paths_splitup_Reorg{path_to_check}(h, 2);
                        z_mid_path = Paths_splitup_Reorg{path_to_check}(h, 3);
                 
                        dist_coll_mid = sqrt((checking_point(1) -...
                            x_mid_path)^2 + (checking_point(2) -...
                            y_mid_path)^2 + (checking_point(3) - z_mid_path)^2);
                        if dist_coll_mid <= search_rad
                            %Then we have a collision
                            number_of_collisions = number_of_collisions + 1;                
                            coll_cell{k}(number_of_collisions, 1) = c;                     
                            coll_cell{k}(number_of_collisions, 2) =...
                                checking_point(1);     
                            coll_cell{k}(number_of_collisions, 3) =...
                                checking_point(2);
                            coll_cell{k}(number_of_collisions, 4) =...
                                checking_point(3);
                            
                            if z_end_current - z_end_prev > 0                   
                                coll_cell{k}(number_of_collisions, 5) = h;      
                            else 
                                coll_cell{k}(number_of_collisions, 5) =...
                                    length(Paths_splitup_Reorg{k}(:,1));
                            end
                            coll_check_1 = 1;                                
                        else
                            coll_check_1 = 0;
                        end
                        h = h + 1;
                    end
                end
            end %For loop goes through all the candidate paths
        end %Else we are still dealing with the first non-horizontal path
    end %Else we are still dealing with horizontal extrusions
    
    %To determine if any collision points are shared
    if coll_cell{k}(1,1) ~= 0     %Then we have at least 1 collision entry
        coll_cell{k} = sortrows(coll_cell{k}, 5);
        if length(coll_cell{k}(:, 1)) >= 2           
            %May want to change the below to a while statement . . .
            r = 1;
            while r < length(coll_cell{k}(:, 1))   
                reps = 0;
                for f = r + 1 : length(coll_cell{k}(:, 1)) 
                    %Check point r against point f:
                    dist_double = sqrt((coll_cell{k}(r, 2) -...
                        coll_cell{k}(f, 2))^2 + (coll_cell{k}(r, 3)...
                        - coll_cell{k}(f, 3))^2 + (coll_cell{k}(r, 4)...
                        - coll_cell{k}(f, 4))^2);
                    if dist_double <= search_rad 
                        reps = reps + 1;
                        r = r + 1;
                    end
                end
                coll_cell{k}(r, 6) = reps;
                r = r + 1;
            end
            %Then re-sort rown to ensure reps entry goes in correct place
            coll_cell{k} = sortrows(coll_cell{k}, [5, 6], {'ascend' 'descend'});  
        else %for only 2 rows in the cell array
            coll_cell{k}(1, 6) = 0;
        end
    end %If col 6 entry has a value of n: then
    
    
    
    %For each point within path k:
    crash_down_zone_start = 0;
    crash_down_zone_end = 0;
    
    
    
    for m = 1 : length(Paths_splitup_Reorg{k}(:,1)) - 1      
        %Current points:
        x_cur =  Paths_splitup_Reorg{k}(m, 1);
        y_cur =  Paths_splitup_Reorg{k}(m, 2);
        z_cur =  Paths_splitup_Reorg{k}(m, 3);
        %Next points (the next row):
        x_nxt =  Paths_splitup_Reorg{k}(m+1, 1);
        y_nxt =  Paths_splitup_Reorg{k}(m+1, 2);
        z_nxt =  Paths_splitup_Reorg{k}(m+1, 3);
        %Find the vectors:
        x_delta = (x_nxt - x_cur);                             
        y_delta = (y_nxt - y_cur);
        z_delta = (z_nxt - z_cur);
        %Find the length of the projection onto the xy-plane
        del_xy_proj = sqrt(x_delta^2 + y_delta^2);
    
        phi = abs(round(atan(del_xy_proj/z_delta), 4));    
        theta = atan(y_delta/x_delta);
        %See notes on the adjustment rationale:
        if x_delta < 0  %Then we add pi
            theta = theta + pi;
        else    %x_delta >= 0
            if y_delta < 0
                theta = theta + 2*pi;
            end
        end
        %To fix bug in case phi is nearly zero >>>>
        if abs(phi) <=  0.005
            theta = 0;
        end
    
        if (x_delta == 0) && (y_delta == 0) && (z_delta) == 0
            mes8 = ['E! Two duplicate points included in the same path. Path ',...
                num2str(k), ' point ', num2str(m)];
            disp(mes8);
        end      
        PHI{k}(m,1) = phi;
        THETA{k}(m,1) = theta;
        %Apply inclination control to phi: use phi_inc (inclined)
        if strcmp(Inclination, 'Nonlinear') == 1    %(The two are identical)
            
            if (Sorted_rank(k) == 2) || (Sorted_rank(k) == 3)                    
                if (0 <= abs(phi)) && (abs(phi) <= lin_lim)
                    phi_inc = phi;                         
                    
                else   
                    if phi < 0
                        phi_inc = -(0.2735*(abs(phi))^3 -...
                            1.13*(abs(phi))^2 + 1.6058*(abs(phi)) - 0.0822);                        
                    else %if Ry is >= 0
                        phi_inc = 0.2735*(phi)^3 - 1.13*(phi)^2...
                        + 1.6058*(phi) - 0.0822;
                    end
                end
            else %Extrusion is horizontal (Rank ==1)
                phi_inc = 0;
            end
            
        else                          %Linear inclination control
            
            if (Sorted_rank(k) == 2) || (Sorted_rank(k) == 3)
                phi_inc = (1-incl/100)*phi;
                
                
            else %Rank is 1 (horizontal)
                phi_inc = 0;
            end
        end
        PHI_inc{k}(m,1) = phi_inc;
        PHI_inc_coll_a{k}(m,1) = phi_inc; 

        del_x_next = Noz_length_imag*sin(phi_inc)*cos(theta);   
        del_y_next = Noz_length_imag*sin(phi_inc)*sin(theta);
        del_z_next = Noz_length_imag*cos(phi_inc);
        

        xy_check{k}(m, 1) = x_cur + del_x_next;
        xy_check{k}(m, 2) = y_cur + del_y_next;
        xy_check{k}(m, 3) = z_cur + del_z_next;
        xy_check{k}(m, 4) = 0;
        xy_check{k}(m, 5) = x_nxt;
        xy_check{k}(m, 6) = y_nxt;
        xy_check{k}(m, 7) = z_nxt;
        xy_check{k}(m, 8) = 0;
        xy_check{k}(m, 9) = phi;
        xy_check{k}(m, 10) = phi_inc;
        %Above checks only valid if imag nozzle length == element length
        %Get next values from current values using deltas
        x_next = x_cur + del_x_next;                
        y_next = y_cur + del_y_next;
        z_next = z_cur + del_z_next;
        
%///////COLLISION AVOIDANCE/////////////////////////////////////////////
        if coll_cell{k}(1,1) ~= 0           
            index_check = 1;
            for r = 1 : length(coll_cell{k}(:, 1))
                if coll_cell{k}(r, 5) < m               
                    index_check = index_check + 1;     
                end
            end
            if index_check > length(coll_cell{k}(:, 1))
                nr_of_bubbles = 0;
            else
                nr_of_bubbles = length(coll_cell{k}...
                    (index_check : length(coll_cell{k}(:, 1)),1)) -...
                    sum(coll_cell{k}(index_check : length(coll_cell{k}...
                    (:, 1)), 6)); 
            end       
            
            if nr_of_bubbles ~= 0
                w = index_check;   
                p = 1;
                %Initialize storage:
                x_coll = zeros(nr_of_bubbles, 1);
                y_coll = zeros(nr_of_bubbles, 1);
                z_coll = zeros(nr_of_bubbles, 1);
                index_coll = zeros(nr_of_bubbles, 1);
                while p <= nr_of_bubbles
                    x_coll(p) = coll_cell{k}(w,2);
                    y_coll(p) = coll_cell{k}(w,3);
                    z_coll(p) = coll_cell{k}(w,4);
                    index_coll(p) = coll_cell{k}(w, 5);
                    %index the two counters:
                    w = w + coll_cell{k}(w, 6) + 1;     
                    p = p + 1;
                end
                %Find vector from TCP to NTP
                vec_noz = [x_next - x_cur, y_next - y_cur, z_next - z_cur];                
                %Now we find d_coll for each of the above collision bubbles:
                %Initialize storage for below for loop:
                %vec_coll = zeros(nr_of_bubbles, 3);
                d_coll = zeros(nr_of_bubbles, 1);
                d_coll_x = zeros(nr_of_bubbles, 1);
                d_coll_y = zeros(nr_of_bubbles, 1);
                d_coll_z = zeros(nr_of_bubbles, 1);
                d_coll_H = zeros(nr_of_bubbles, 1);
                for r = 1 : nr_of_bubbles
                    vec_coll = [x_coll(r) - x_cur, y_coll(r)...
                        - y_cur, z_coll(r) - z_cur];                 
                    alpha = acos(round(dot(vec_noz, vec_coll)/...
                        (norm(vec_noz)*norm(vec_coll)), 5));
                    length_to_end = norm(vec_coll);
                    d_coll(r) = length_to_end*sin(alpha);                                         
                    length_along_noz = length_to_end*cos(alpha); 
                    e_noz = vec_noz/norm(vec_noz); 
                    vec_cur_to_noz_coll = e_noz*length_along_noz;                            
                    vec_coll = - vec_coll + vec_cur_to_noz_coll;
                    d_coll_x(r) = vec_coll(1); 
                    d_coll_y(r) = vec_coll(2);
                    d_coll_z(r) = vec_coll(3);
                    d_coll_H(r) = sqrt(d_coll_x(r)^2 + d_coll_y(r)^2); 
                    %////////////////////////////////////////////////
                end  %We have now found all the d_coll values . . .
                d_coll_MIN = min(d_coll);
                d_coll_z_MIN = min(d_coll_z);
                if  (d_coll_MIN <= nozzle_clearance) || (d_coll_z_MIN < 0)                                                                   
                    %Set the phi limits
                    if phi <= phi_slim     
                        phi_lim = abs(phi - phi_slim);  
                    else
                        phi_lim = 0;
                    end
                    cap = 0;      
                    sign = 1;   
                    while (cap == 0) && ((d_coll_MIN <= nozzle_clearance)...
                            ||((d_coll_z_MIN < 0) && (sign == 1)))      
                        
                        phi_inc = phi_inc - sign*phi_increment;                             
                        %phi_lim has been set above:
                        if phi_lim ~= 0                     
                            if phi_inc < 0                 
                                phi_inc = abs(phi_inc);     
                                theta = theta + pi;        
                                sign  = -1;                 
                            end
                            if sign == -1
                                
                                if phi_inc >= phi_lim       
                                    phi_inc = phi_lim;      
                                    cap = 1;                
                                end            
                            end
                        else %phi_lim == 0
                            if phi_inc <= 0
                                phi_inc = 0; 
                                cap = 1;            
                            end
                        end 
                        xy_check{k}(m, 11) = phi_inc;
                        %Find updated (x, y, z)_next values
                        del_x_next = Noz_length_imag*sin(phi_inc)*cos(theta);   
                        del_y_next = Noz_length_imag*sin(phi_inc)*sin(theta);
                        del_z_next = Noz_length_imag*cos(phi_inc);
                        
                        x_next = x_cur + del_x_next;         
                        y_next = y_cur + del_y_next;
                        z_next = z_cur + del_z_next;
                        vec_noz = [x_next - x_cur, y_next - y_cur, z_next - z_cur];
                        for v = 1 : nr_of_bubbles
                            %Find vector to end of path (collision point)
                            vec_coll = [round((x_coll(v) - x_cur), 4),...
                                round((y_coll(v) - y_cur), 4),...
                                round((z_coll(v) - z_cur), 4)];
                            %Find alpha using dot product
                            alpha = acos(round(dot(vec_noz, vec_coll)/...
                                (norm(vec_noz)*norm(vec_coll)), 5));
                            %Find length of vec_end
                            length_to_end = norm(vec_coll);
                            d_coll(v) = length_to_end*sin(alpha);
                            length_along_noz = length_to_end*cos(alpha); 
                            e_noz = vec_noz/norm(vec_noz);                          
                            vec_cur_to_noz_coll = e_noz*length_along_noz;           
                            vec_coll = - vec_coll + vec_cur_to_noz_coll;
                            d_coll_x(v) = vec_coll(1); 
                            d_coll_y(v) = vec_coll(2);
                            d_coll_z(v) = vec_coll(3);
                            d_coll_H(v) = sqrt(d_coll_x(v)^2 + d_coll_y(v)^2); 
                        end
                        
                        d_coll_MIN = min(d_coll);
                        d_coll_z_MIN = min(d_coll_z);
                    end
                    
                end
            end 
            PHI_inc_coll_a{k}(m,1) = phi_inc;
            if (index_check <= length(coll_cell{k}(:, 1))) &&...
                    (m == coll_cell{k}(index_check, 5))        
                %Specify start and end of zone:
                crash_down_zone_start = m;
                crash_down_zone_end = m + relax_index_length;
                Mes10 = ['We have identified a crash-down zone starting at ',...
                    num2str(crash_down_zone_start), ' and ending at ',...
                    num2str(crash_down_zone_end)];
                disp(Mes10)
            end
            
            
            
            %Next: check if we are in the "crash-down" zone
            if (crash_down_zone_start <= m) &&...
                    (m <= crash_down_zone_end) && (m > 1)  
                disp('we are currently in a crash-down zone');
                phi_upper = PHI_inc_coll{k}(m - 1, 1);
                phi_lower = phi_inc;
                phi_gap = phi_lower - phi_upper;            
                %Find the incremental value with which to adjust phi
                phi_decrement = phi_gap/(crash_down_zone_end - m + 1);
                %Apply the decrement value to phi_inc
                phi_inc = phi_upper + phi_decrement;
                %and re-define the NTP
                del_x_next = Noz_length_imag*sin(phi_inc)*cos(theta);   
                del_y_next = Noz_length_imag*sin(phi_inc)*sin(theta);
                del_z_next = Noz_length_imag*cos(phi_inc);
                x_next = x_cur + del_x_next;               
                y_next = y_cur + del_y_next;
                z_next = z_cur + del_z_next;           
            end
        end  
        %Apply collision control to theta:
        theta_inc = theta;  %No adjustments yet made to theta_inc
        
        %Pop the above values in our storage cell array
        %Format: x, y, z, d, x_next, y_next, z_next
        Paths_planned{k}(m, 1) = x_cur;
        Paths_planned{k}(m, 2) = y_cur;
        Paths_planned{k}(m, 3) = z_cur;
        Paths_planned{k}(m, 4) = Paths_splitup_Reorg{k}(m, 4); %diameter
        Paths_planned{k}(m, 5) = x_next;
        Paths_planned{k}(m, 6) = y_next;
        Paths_planned{k}(m, 7) = z_next;  
        %Store phi_inc & theta_inc for plotting in main script:
        PHI_inc_coll{k}(m,1) = phi_inc;                                        
        THETA_inc{k}(m,1) = theta_inc;
        
    end
    
end     
for f = 1 : Number_of_paths
    N_pp = length(Paths_splitup_Reorg{f}(:, 1));  %N used for paths_planned
    
    %x, y, z and diameter
    Paths_planned{f}(N_pp, 1) = Paths_splitup_Reorg{f}(N_pp, 1);
    Paths_planned{f}(N_pp, 2) = Paths_splitup_Reorg{f}(N_pp, 2);
    Paths_planned{f}(N_pp, 3) = Paths_splitup_Reorg{f}(N_pp, 3);
    Paths_planned{f}(N_pp, 4) = Paths_splitup_Reorg{f}(N_pp, 4);
    delta_dummy = Noz_length_imag;            
    phi_inc_last = PHI_inc_coll{f}(length(PHI_inc_coll{f}(:,1)), 1);
    theta_inc_last = THETA_inc{f}(length(THETA_inc{f}(:,1)), 1);
    del_z_last = delta_dummy*cos(phi_inc_last);
    del_x_last = delta_dummy*sin(phi_inc_last)*cos(theta_inc_last);
    del_y_last = delta_dummy*sin(phi_inc_last)*sin(theta_inc_last);
    %Then add onto the final xyz values of each path
    x_next_final = Paths_splitup_Reorg{f}(N_pp, 1) + del_x_last;
    y_next_final = Paths_splitup_Reorg{f}(N_pp, 2) + del_y_last;
    z_next_final = Paths_splitup_Reorg{f}(N_pp, 3) + del_z_last;
    %And pop them into Paths_planned
    Paths_planned{f}(N_pp, 5) = x_next_final;
    Paths_planned{f}(N_pp, 6) = y_next_final;
    Paths_planned{f}(N_pp, 7) = z_next_final;
    
    
    
    %and the final values for phi, theta, phi_inc, theta_inc
    PHI{f}(N_pp,1) = PHI{f}(N_pp - 1,1);
    THETA{f}(N_pp,1) = THETA{f}(N_pp - 1,1);
    
    PHI_inc_coll{f}(N_pp,1) = PHI_inc_coll{f}(N_pp - 1,1);
    THETA_inc{f}(N_pp,1) = THETA_inc{f}(N_pp - 1,1);
    
end
disp('     ');
end