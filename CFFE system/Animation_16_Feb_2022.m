%To add:
% - A tracing function to set whether the inbetween lines stay on or not .
%

function flick = Animation_16_Feb_2022(Tracers, Nozzle_tracers, Tool_bed, Tool_start_ALL, Tool_pose_ALL, Paths_planned, Tool_end_comb_ALL, span, y, z, X_MIN, X_MAX, Y_MIN, Y_MAX, Z_MAX, z_offset_bed, bump_dist)
%Set the axis buffers . . .
Buffer = 20;
Noz_length = 60;        %Height diff. between upper and lower nozzle points.

%Color specification:
move_in = [1 0.7 0.8];
Tool_start_c = 'm';
Tool_end_1_c = [0.2 0.1 0.6];         %Set_dist
Tool_end_2_c = [0.1 0.7 0.9];         %Cut_dist
Tool_end_3_c = [1 0.5 1];             %Cutting point
Tool_end_4_c = [1 0.6 0];             %Move away
End_to_start_tool_c = 'c';
Extrusion_c = 'r';
noz_col = 'b';
noz_untilt_col = 'k';

%Calculate the axis limits for the plot:
%X
%X_min
X_MIN_plot = X_MIN - Buffer;
%X_max
X_MAX_plot = X_MAX + Buffer;

%Y
%Y_min
Y_MIN_plot = Y_MIN - Buffer;
%Y_max
Y_MAX_plot = Y_MAX + Buffer;

%Do the plotting
%Storage for stringing tracers together:
string1 = zeros(2,3);
string2 = zeros(2,3);
string3 = zeros(2,3);
string4 = zeros(2,3);
string5 = zeros(2,3);
string6 = zeros(2,3);
string7 = zeros(2,3);
string8 = zeros(2,3);


if z == 1       %First point %This is a tracer plot
    if y == 1   %Then we are dealing with the first path
        string1 = [Tool_bed(1), Tool_bed(2), Tool_bed(3) + z_offset_bed + bump_dist; Tool_start_ALL{1}(1), Tool_start_ALL{1}(2), Tool_start_ALL{1}(3)];
        plot3(string1(:,1), string1(:,2), string1(:,3), 'color', move_in, 'linewidth', 1.5)
        hold on
    else  %(y is > 1 and there is a pre-decessor which is the last end tool from the previous path)
        A = [Tool_end_comb_ALL{y-1}(4, 1), Tool_end_comb_ALL{y-1}(4, 2), Tool_end_comb_ALL{y-1}(4, 3)];
        B = [Tool_start_ALL{y}(1), Tool_start_ALL{y}(2), Tool_start_ALL{y}(3)];
        string1 = [A;B];
        plot3(string1(:,1), string1(:,2), string1(:,3), 'color', End_to_start_tool_c, 'linewidth', 1.5)
        hold on
    end
    
else
    if (z >= 2) && (z <= span+1) %z is between 2 and the end %The path officially starts at point 2 . . . due to the start tool . . .
        %Moving from end tool to start of the extrusion
        if z == 2  %Then we are about to start the extrusion phase
            B = [Tool_start_ALL{y}(1), Tool_start_ALL{y}(2), Tool_start_ALL{y}(3)];
            C = [Tool_pose_ALL{y}(1,2), Tool_pose_ALL{y}(1,3), Tool_pose_ALL{y}(1,4)];
            string2 = [B;C];
            plot3(string2(:,1), string2(:,2), string2(:,3), 'color', Tool_start_c, 'linewidth', 1.5)
            hold on
        end
        
        %Theres a bug in here for short paths (only a few points) . . .
        
        %The below indices are presumably correct . . .
        plot3(Tool_pose_ALL{y}(1:z-1,2), Tool_pose_ALL{y}(1:z-1,3), Tool_pose_ALL{y}(1:z-1,4), 'color', Extrusion_c, 'linewidth', 3)   %Plots everything in the path up to the current point
        hold on
        if strcmp(Nozzle_tracers, 'ON') == 1
            plot3((Paths_planned{y}(1 : z-1, 5)+ Tool_bed(1)), (Paths_planned{y}(1 : z-1, 6) + Tool_bed(2)), (Paths_planned{y}(1 : z-1, 7) + Tool_bed(3) + z_offset_bed), 'color', Tool_start_c, 'linewidth', 1.5)
            hold on
        end
        
        
        %END TOOLS
    else %z has to be > span (ie +2, +3, +4 or +5) % z is one of the end tools
        if z == span + 2   %This is the first point along the Tool_end path
            M = [Tool_pose_ALL{y}(span, 2), Tool_pose_ALL{y}(span, 3), Tool_pose_ALL{y}(span, 4)];
            N = [Tool_end_comb_ALL{y}(1, 1), Tool_end_comb_ALL{y}(1, 2), Tool_end_comb_ALL{y}(1, 3)];
            string6 = [M;N];
            plot3(string6(:,1), string6(:,2), string6(:,3), 'color', Tool_end_1_c, 'linewidth', 3)
            hold on
            %And plot the previous path in its entirety
            plot3(Tool_pose_ALL{y}(:,2), Tool_pose_ALL{y}(:,3), Tool_pose_ALL{y}(:,4), 'color', Extrusion_c, 'linewidth', 3)
            hold on
        end
        
        
        %%% Need to change this so we can see the end moves in more detail . . .
        
        if z == span + 3
            M = [Tool_pose_ALL{y}(span, 2), Tool_pose_ALL{y}(span, 3), Tool_pose_ALL{y}(span, 4)];
            N = [Tool_end_comb_ALL{y}(1, 1), Tool_end_comb_ALL{y}(1, 2), Tool_end_comb_ALL{y}(1, 3)];
            O = [Tool_end_comb_ALL{y}(2, 1), Tool_end_comb_ALL{y}(2, 2), Tool_end_comb_ALL{y}(2, 3)];
            string6 = [M;N];
            string7 = [N;O];
            plot3(string7(:,1), string7(:,2), string7(:,3), 'color', Tool_end_2_c, 'linewidth', 3)
            hold on
            %And plot the previous path in its entirety
            plot3(Tool_pose_ALL{y}(:,2), Tool_pose_ALL{y}(:,3), Tool_pose_ALL{y}(:,4), 'color', Extrusion_c, 'linewidth', 3)
            hold on
            plot3(string6(:,1), string6(:,2), string6(:,3), 'color', Tool_end_1_c, 'linewidth', 3)
            hold on
        end
        
        if z == span + 4
            M = [Tool_pose_ALL{y}(span, 2), Tool_pose_ALL{y}(span, 3), Tool_pose_ALL{y}(span, 4)];
            N = [Tool_end_comb_ALL{y}(1, 1), Tool_end_comb_ALL{y}(1, 2), Tool_end_comb_ALL{y}(1, 3)];
            O = [Tool_end_comb_ALL{y}(2, 1), Tool_end_comb_ALL{y}(2, 2), Tool_end_comb_ALL{y}(2, 3)];
            P = [Tool_end_comb_ALL{y}(3, 1), Tool_end_comb_ALL{y}(3, 2), Tool_end_comb_ALL{y}(3, 3)];
            string6 = [M;N];
            string7 = [N;O];
            string8 = [O;P];
            plot3(string8(:,1), string8(:,2), string8(:,3), 'color', Tool_end_3_c, 'linewidth', 3)
            hold on
            %And plot the previous path in its entirety
            plot3(Tool_pose_ALL{y}(:,2), Tool_pose_ALL{y}(:,3), Tool_pose_ALL{y}(:,4), 'color', Extrusion_c, 'linewidth', 3)
            hold on
            plot3(string6(:,1), string6(:,2), string6(:,3), 'color', Tool_end_1_c, 'linewidth', 3)
            hold on
            plot3(string7(:,1), string7(:,2), string7(:,3), 'color', Tool_end_2_c, 'linewidth', 3)
            hold on
        end
        
        if z == span + 5
            M = [Tool_pose_ALL{y}(span, 2), Tool_pose_ALL{y}(span, 3), Tool_pose_ALL{y}(span, 4)];
            N = [Tool_end_comb_ALL{y}(1, 1), Tool_end_comb_ALL{y}(1, 2), Tool_end_comb_ALL{y}(1, 3)];
            O = [Tool_end_comb_ALL{y}(2, 1), Tool_end_comb_ALL{y}(2, 2), Tool_end_comb_ALL{y}(2, 3)];
            P = [Tool_end_comb_ALL{y}(3, 1), Tool_end_comb_ALL{y}(3, 2), Tool_end_comb_ALL{y}(3, 3)];
            Q = [Tool_end_comb_ALL{y}(4, 1), Tool_end_comb_ALL{y}(4, 2), Tool_end_comb_ALL{y}(4, 3)];
            string6 = [M;N];
            string7 = [N;O];
            string8 = [O;P];
            string9 = [P;Q];
            plot3(string9(:,1), string9(:,2), string9(:,3), 'color', Tool_end_4_c, 'linewidth', 1.5)
            hold on
            %And plot the previous path in its entirety
            plot3(Tool_pose_ALL{y}(:,2), Tool_pose_ALL{y}(:,3), Tool_pose_ALL{y}(:,4), 'color', Extrusion_c, 'linewidth', 3)
            hold on
            plot3(string6(:,1), string6(:,2), string6(:,3), 'color', Tool_end_1_c, 'linewidth', 3)
            hold on
            plot3(string7(:,1), string7(:,2), string7(:,3), 'color', Tool_end_2_c, 'linewidth', 3)
            hold on
            plot3(string8(:,1), string8(:,2), string8(:,3), 'color', Tool_end_3_c, 'linewidth', 3)
            hold on
        end
    end
end


axis equal
xlim([X_MIN_plot X_MAX_plot])
ylim([Y_MIN_plot Y_MAX_plot])
zlim([20 (Z_MAX + Noz_length + Buffer)])
hold on
xlabel('X')
ylabel('Y')
camva manual

%If necessary, plot previous paths coming before current path . . .
%These will be plotted regardsless of the value of z . . .

if y > 1
    for s = 1 : y-1
        
        plot3(Tool_pose_ALL{s}(:,2), Tool_pose_ALL{s}(:,3), Tool_pose_ALL{s}(:,4), 'color', Extrusion_c, 'linewidth', 3);               %Tool_pose_ALL{s}(:,4));
        hold on
    end
end



%//////////////Tracing/////////////////////////////////////////////////////
%Also: plot the previous tracers if necessary:
if strcmp(Tracers, 'ON') == 1           %Returns 1 if the two strings are equal . . .
    %If ON: then plot ALL of the previous paths up to the current  . . .
    %Plot the Tool_starts
    %From zero pt to the start of tool_start . . .
    string3 = [Tool_bed(1), Tool_bed(2), Tool_bed(3) + z_offset_bed + bump_dist; Tool_start_ALL{1}(1), Tool_start_ALL{1}(2), Tool_start_ALL{1}(3)];
    plot3(string3(:,1), string3(:,2), string3(:,3), 'color',  move_in, 'linewidth', 1.5)
    hold on
    
    
    if y > 1
        %From tool_end to next tool_start
        for c = 1 : y-1
            E = [Tool_end_comb_ALL{c}(4, 1), Tool_end_comb_ALL{c}(4, 2), Tool_end_comb_ALL{c}(4, 3)];
            F = [Tool_start_ALL{c+1}(1), Tool_start_ALL{c+1}(2), Tool_start_ALL{c+1}(3)];
            string4 = [E;F];
            plot3(string4(:,1), string4(:,2), string4(:,3), 'color', End_to_start_tool_c, 'linewidth', 1.5)
            hold on
        end
        
        
        
        
        
        for r = 1 : y - 1
            N = [Tool_end_comb_ALL{r}(1, 1), Tool_end_comb_ALL{r}(1, 2), Tool_end_comb_ALL{r}(1, 3)];
            O = [Tool_end_comb_ALL{r}(2, 1), Tool_end_comb_ALL{r}(2, 2), Tool_end_comb_ALL{r}(2, 3)];
            P = [Tool_end_comb_ALL{r}(3, 1), Tool_end_comb_ALL{r}(3, 2), Tool_end_comb_ALL{r}(3, 3)];
            Q = [Tool_end_comb_ALL{r}(4, 1), Tool_end_comb_ALL{r}(4, 2), Tool_end_comb_ALL{r}(4, 3)];
            string7 = [N;O];
            string8 = [O;P];
            string9 = [P;Q];
            plot3(string7(:,1), string7(:,2), string7(:,3), 'color', Tool_end_2_c, 'linewidth', 3)
            hold on
            plot3(string8(:,1), string8(:,2), string8(:,3), 'color', Tool_end_3_c, 'linewidth', 3)
            hold on
            plot3(string9(:,1), string9(:,2), string9(:,3), 'color', Tool_end_4_c, 'linewidth', 1.5)
            hold on
        end
        
    end
    
    %From the end of Tool_start to the start of the extrusion (for the current extrusion and the previous ones)
    % if z >= 2 %The we have plotted the first point on the extrusion and we can plot this now
    if z >=2
        lim1 = y;
    else
        lim1 = y - 1;
    end
    for d = 1 : lim1
        G = [Tool_start_ALL{d}(1), Tool_start_ALL{d}(2), Tool_start_ALL{d}(3)];
        H = [Tool_pose_ALL{d}(1,2), Tool_pose_ALL{d}(1,3), Tool_pose_ALL{d}(1,4)];
        string5 = [G;H];
        plot3(string5(:,1), string5(:,2), string5(:,3), 'color', Tool_start_c, 'linewidth', 1.5)
        hold on
    end
    
    if z >= span + 2
        lim2 = y;
    else
        lim2 = y - 1;
    end
    for r = 1 : lim2
        %The bit between end of tool_pose and start of tool_end
        P = [Tool_pose_ALL{r}(length(Tool_pose_ALL{r}), 2), Tool_pose_ALL{r}(length(Tool_pose_ALL{r}), 3), Tool_pose_ALL{r}(length(Tool_pose_ALL{r}), 4)];
        Q = [Tool_end_comb_ALL{r}(1, 1), Tool_end_comb_ALL{r}(1, 2), Tool_end_comb_ALL{r}(1, 3)];
        string7 = [P;Q];
        plot3(string7(:,1), string7(:,2), string7(:,3), 'color', Tool_end_1_c, 'linewidth',3)
        hold on
    end
end


%Plot the rest of the junk: nozzle etc:
%Start with the nozzle without inclination control . . .
Noz_lower = zeros(1, 3);
Noz_upper = zeros(1, 3);
Noz_comb_untilted = zeros(2, 3);
Noz_comb = zeros(2, 3);


if z == 1
    Noz_lower = [Tool_start_ALL{y}(1), Tool_start_ALL{y}(2), Tool_start_ALL{y}(3)];
    Noz_upper_untilted = [Tool_start_ALL{y}(1), Tool_start_ALL{y}(2), Tool_start_ALL{y}(3) + Noz_length];
else
    if (z >= 2) && (z <= span + 1) %z is between 2 and the end
        Noz_lower = [Tool_pose_ALL{y}(z-1,2), Tool_pose_ALL{y}(z-1,3), Tool_pose_ALL{y}(z-1,4)]; %no rotaitons applied to this point
        Noz_upper_untilted = [Tool_pose_ALL{y}(z-1,2), Tool_pose_ALL{y}(z-1,3), Tool_pose_ALL{y}(z-1,4) + Noz_length];
    else
        %Use one of the end tools
        Noz_lower = [Tool_end_comb_ALL{y}((z - (span+1)), 1), Tool_end_comb_ALL{y}((z - (span+1)), 2), Tool_end_comb_ALL{y}((z - (span+1)), 3)];
        Noz_upper_untilted = [Tool_end_comb_ALL{y}((z - (span+1)), 1), Tool_end_comb_ALL{y}((z - (span+1)), 2), Tool_end_comb_ALL{y}((z - (span+1)), 3) + Noz_length];
    end
end





%/////////////////////////////////////////////////////////////////////////////////////////////////////////////
%Plot the nozzle using the actual toolpath calcs
%ie: using OUTPUT data NOT INPUT DATA

%Plot the untilted nozzle (nice and thin . . .)
Noz_comb_untilted = [Noz_lower; Noz_upper_untilted];
plot3(Noz_comb_untilted(:,1), Noz_comb_untilted(:,2), Noz_comb_untilted(:,3), 'color', noz_untilt_col, 'linewidth', 1.5)
hold on


%Now plot the tilted nozzle (the "real" nozzle)
if z == 1
    Ry_noz = (pi/180)*Tool_start_ALL{y}(5);
    Rx_noz = (pi/180)*Tool_start_ALL{y}(4);
else
    if (z >=2) && (z <= span + 1)
        Ry_noz = (pi/180)*Tool_pose_ALL{y}(z-1, 6);          %Note: negate and turn back to radians . . .
        Rx_noz = (pi/180)*Tool_pose_ALL{y}(z-1, 5);
    else   %We use the Tool_ends
        Ry_noz = (pi/180)*Tool_end_comb_ALL{y}((z - (span+1)), 5);
        Rx_noz = (pi/180)*Tool_end_comb_ALL{y}((z - (span+1)), 4);
    end
end

%Use the same Noz_lower ans Noz_upper_untilted as before:
del_x = 0;%Noz_upper_untilted(1) - Noz_lower(1);
del_y = 0;%Noz_upper_untilted(2) - Noz_lower(2);
del_z = Noz_length;


%NOTE: rotation matrices are set up the way the robot would interpret
%(differs from the ones used in calculating Rx)
%First do Rx
del_x_Rx = del_x;
del_y_Rx = del_y*cos(Rx_noz) - del_z*sin(Rx_noz);
del_z_Rx = del_y*sin(Rx_noz) + del_z*cos(Rx_noz);

%Then apply Ry:
del_x_Rx_Ry = del_x_Rx*cos(Ry_noz) + del_z_Rx*sin(Ry_noz);
del_y_Rx_Ry = del_y_Rx;
del_z_Rx_Ry = -del_x_Rx*sin(Ry_noz) + del_z_Rx*cos(Ry_noz);



Noz_upper = [Noz_lower(1) + del_x_Rx_Ry, Noz_lower(2) + del_y_Rx_Ry, Noz_lower(3) + del_z_Rx_Ry];
Noz_comb = [Noz_lower; Noz_upper];

plot3(Noz_comb(:,1), Noz_comb(:,2), Noz_comb(:,3), 'color', noz_col, 'linewidth', 4.0)
hold on

%///////////////////////////////////////////////////////////////////////////////////////////////////////////////

hold off
flick = getframe;
