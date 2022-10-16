function WriteJob_25_May_2020(Number_of_paths, N_rows_per_path,...
    Tool_bed, Tool_pose_ALL, Prime_time_ALL, Retraction_time_ALL,...
    Retraction_time_at_Prime_spd_ALL, JobName, JobFile, dateTime,...
    Tool, n_lightsoff_ALL, Stoppage_delay_ALL,Tool_end_comb_ALL,...
    Tool_start_ALL, z_end_spd, C_noz_tip,Extruder_spd_out_1,...
    Extruder_spd_out_2, Extruder_spd_out_3, LEDs_out, Lasers_out,...
    Interrupt_out,sig_spd_1, sig_spd_2, sig_spd_3, sig_spd_4,...
    sig_spd_5, sig_spd_6, sig_spd_7,Calibration_speed_VJ,...
    Approach_Speed, Inbetween_speed, bump_dist, z_offset_bed,...
    Raise_speed, Sorted_rank, No_horizontal_paths,...
    UVBox_delay, UV_move_speed)

Interrupt = 'OFF';
%/////////////////////////////////////////////////////////////////////
fileID = fopen(JobFile , 'w');
fprintf(fileID,'/JOB\r\n');
fprintf(fileID,'//NAME %s\r\n', JobName);
fprintf(fileID,'//POS\r\n');
fprintf(fileID,'///NPOS %d,0,0,%d,0,0\r\n',sum(N_rows_per_path)...
    + 5*Number_of_paths + 1, sum(N_rows_per_path)...
    + 5*Number_of_paths + 1);
fprintf(fileID,'///TOOL %d\r\n', Tool);
%For C coordinates:
fprintf(fileID,'///POSTYPE ROBOT\r\n');
fprintf(fileID,'///RECTAN\r\n');
fprintf(fileID,...
    '///RCONF 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\r\n');

%////////////////////////////////////////////////////////////////////
for k = 1 : (sum(N_rows_per_path) + 5*Number_of_paths) + 1
    fprintf(fileID,'C%05d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n',...
        k - 1, C_noz_tip(1), C_noz_tip(2), C_noz_tip(3),...
        C_noz_tip(4), C_noz_tip(5), C_noz_tip(6), C_noz_tip(7));
end

%For P points
fprintf(fileID,'///POSTYPE ROBOT\r\n');
fprintf(fileID,'///RECTAN\r\n');
fprintf(fileID,...
    '///RCONF 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\r\n');
fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n',...
    0, Tool_bed(1), Tool_bed(2), Tool_bed(3) + z_offset_bed +...
    bump_dist, Tool_bed(4), Tool_bed(5), Tool_bed(6), Tool_bed(7));

for d = 1 : Number_of_paths
    %The start tool would go in here . . . .
    fprintf(fileID,...
        'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,...%.4f,%.4f\r\n',...
        (Tool_pose_ALL{d}(1,1)-1), Tool_start_ALL{d}(1,1),...
        Tool_start_ALL{d}(1,2),Tool_start_ALL{d}(1,3),...
        Tool_start_ALL{d}(1,4),Tool_start_ALL{d}(1,5),...
        Tool_start_ALL{d}(1,6),Tool_start_ALL{d}(1,7));
    
    for i = 1 : N_rows_per_path(d)
        fprintf(fileID,...
            'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n',...
            Tool_pose_ALL{d}(i,1), Tool_pose_ALL{d}(i,2),...
            Tool_pose_ALL{d}(i,3), Tool_pose_ALL{d}(i,4),...
            Tool_pose_ALL{d}(i,5), Tool_pose_ALL{d}(i,6),...
            Tool_pose_ALL{d}(i,7), Tool_pose_ALL{d}(i,8));
        
    end
    %Then define the final tool (to move away after extrusion
    
    fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n',...
        (Tool_pose_ALL{d}(N_rows_per_path(d),1)+1),...
        Tool_end_comb_ALL{d}(1,1), Tool_end_comb_ALL{d}(1,2),...
        Tool_end_comb_ALL{d}(1,3),Tool_end_comb_ALL{d}(1,4),...
        Tool_end_comb_ALL{d}(1,5),Tool_end_comb_ALL{d}(1,6),...
        Tool_end_comb_ALL{d}(1,7));
    fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n',...
        (Tool_pose_ALL{d}(N_rows_per_path(d),1)+2),...
        Tool_end_comb_ALL{d}(2,1), Tool_end_comb_ALL{d}(2,2),...
        Tool_end_comb_ALL{d}(2,3),Tool_end_comb_ALL{d}(2,4),...
        Tool_end_comb_ALL{d}(2,5),Tool_end_comb_ALL{d}(2,6),...
        Tool_end_comb_ALL{d}(2,7));
    fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n',...
        (Tool_pose_ALL{d}(N_rows_per_path(d),1)+3),...
        Tool_end_comb_ALL{d}(3,1), Tool_end_comb_ALL{d}(3,2),...
        Tool_end_comb_ALL{d}(3,3),Tool_end_comb_ALL{d}(3,4),...
        Tool_end_comb_ALL{d}(3,5),Tool_end_comb_ALL{d}(3,6),...
        Tool_end_comb_ALL{d}(3,7));
    fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n',...
        (Tool_pose_ALL{d}(N_rows_per_path(d),1)+4),...
        Tool_end_comb_ALL{d}(4,1), Tool_end_comb_ALL{d}(4,2),...
        Tool_end_comb_ALL{d}(4,3),Tool_end_comb_ALL{d}(4,4),...
        Tool_end_comb_ALL{d}(4,5),Tool_end_comb_ALL{d}(4,6),...
        Tool_end_comb_ALL{d}(4,7));
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Instruction data
fprintf(fileID,'//INST\r\n');
fprintf(fileID,'///DATE %s\r\n', dateTime);
fprintf(fileID,'///ATTR SC,RW,RJ\r\n');
fprintf(fileID,'////FRAME ROBOT\r\n');
fprintf(fileID,'///GROUP1 RB1\r\n');
fprintf(fileID,'NOP\r\n');

%Ensure all oututs are off before starting:
fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Interrupt_out);
fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Extruder_spd_out_1);
fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Extruder_spd_out_2);
fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Extruder_spd_out_3);
fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Lasers_out);
fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', LEDs_out);

%Move frome current position to approach position
fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n', Tool, 0);
fprintf(fileID, 'MOVJ C%05d VJ=%.2f\r\n', 0, Calibration_speed_VJ);
fprintf(fileID, 'TIMER T=2.000\r\n');
%Now P000 and C0000 have been used up . . . The next point is the
%actual start of the extrusion . . .


for m = 1 : Number_of_paths
    %Use the start tool . . .
    fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n', Tool,...
        (Tool_pose_ALL{m}(1,1)-1));
    fprintf(fileID, 'MOVL C%05d V=%.2f\r\n', ...
        (Tool_pose_ALL{m}(1,1)-1), Approach_Speed/60);
    
    %Move to the start position
    fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',...
        Tool, Tool_pose_ALL{m}(1,1));
    fprintf(fileID, 'MOVL C%05d V=%.2f\r\n', ...
        Tool_pose_ALL{m}(1,1), Inbetween_speed/60);
    
    fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
        Extruder_spd_out_1, sig_spd_1(1));
    fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
        Extruder_spd_out_2, sig_spd_1(2));
    fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
        Extruder_spd_out_3, sig_spd_1(3));
    fprintf(fileID,'TIMER T=0.50\r\n');
    %If loop to flip interrupt value . . .
    %If it was off, put it on.
    if strcmp(Interrupt,'OFF') == 1
        Interrupt = 'ON';
    else
        Interrupt = 'OFF';
    end
    fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
        Interrupt_out, Interrupt);
    
    
    
    if m == 1
        fprintf(fileID,'TIMER T=%.2f\r\n',Prime_time_ALL(m));
    else
        fprintf(fileID,'TIMER T=%.2f\r\n',(Prime_time_ALL(m)...
            + Retraction_time_at_Prime_spd_ALL(m)));
    end
    %All ranks taken care of here
    if (Sorted_rank(m) == 2) || (Sorted_rank(m) == 3)
        
        if Sorted_rank(m) == 2
            Mes1 = ['Path ', num2str(m),...
                ': non-horizontal extrusion of rank 2'];
            disp(Mes1)
        else
            Mes1 = ['Path ', num2str(m),...
                ': non-horizontal extrusion of rank 3'];
            disp(Mes1)
        end
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_1, sig_spd_3(1));
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_2, sig_spd_3(2));
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_3, sig_spd_3(3));
        fprintf(fileID,'TIMER T=0.20\r\n');
        %If loop to flip interrupt value
        %If it was off, put it on. Else, put it off.
        if strcmp(Interrupt,'OFF') == 1
            Interrupt = 'ON';
        else
            Interrupt = 'OFF';
        end
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n', Interrupt_out, Interrupt);
        %The extruder is now going at ext_speed_3
        
        %For extrusions of Rank 2: ligths off extrusion applies.
        %For extrusions of Rank 3: DO NOT NEED lights off extrusion 
        %since we are sufficiently off the bed 
        %For Rank of 3: turn the lights on now
        if Sorted_rank(m) == 3
            fprintf(fileID, 'DOUT OT#(%d) ON\r\n', Lasers_out);
        end
        
        for t = 1 : n_lightsoff_ALL(m) - 1        
            fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',...
                Tool, Tool_pose_ALL{m}(t+1, 1));
            fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',...
                Tool_pose_ALL{m}(t+1, 1), Tool_pose_ALL{m}(t+1,9));
        end
        %For Rank 2: turn the lights on  here:
        if Sorted_rank(m) == 2
            fprintf(fileID, 'DOUT OT#(%d) ON\r\n', Lasers_out);
        end

        for k = n_lightsoff_ALL(m) : N_rows_per_path(m)-1                                                                                      
            fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n', Tool,...
                Tool_pose_ALL{m}(k+1, 1));
            fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',... 
        end

        %Extrude past final point to compensate for setting distance:
        %Will have an if loop here for flat extrusions
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',...
            Tool,(Tool_pose_ALL{m}(N_rows_per_path(m),1)+1));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+1),...
            Tool_pose_ALL{m}(N_rows_per_path(m), 9));                    

        %Retract extruder . . .
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_1, sig_spd_7(1));
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_2, sig_spd_7(2));
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_3, sig_spd_7(3));
        fprintf(fileID,'TIMER T=0.20\r\n');
        
        if strcmp(Interrupt,'OFF') == 1
            Interrupt = 'ON';
        else
            Interrupt = 'OFF';
        end
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n', Interrupt_out, Interrupt);
        
        fprintf(fileID,'TIMER T=%.2f\r\n',Retraction_time_ALL(m));
        %^^Wait while retraction occurs^^

        %Stop extruder:
        fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Extruder_spd_out_1);
        fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Extruder_spd_out_2);
        fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Extruder_spd_out_3);
        %Tell the arduino that there is a signal . . .
        if strcmp(Interrupt,'OFF') == 1
            Interrupt = 'ON';
        else
            Interrupt = 'OFF';
        end
        fprintf(fileID,'TIMER T=0.20\r\n');
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n', Interrupt_out, Interrupt);
        
        %Delay after turning extruder off
        fprintf(fileID,'TIMER T=%.2f\r\n',Stoppage_delay_ALL(m));
        
        %Turn LASERS off
        fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Lasers_out);
        
        
        %Execute final three moves with lights and extruder off
        %z_wipe
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',Tool,...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+2));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+2), z_end_spd/60);
        %x_ and y_wipe:
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',...
            Tool,(Tool_pose_ALL{m}(N_rows_per_path(m),1)+3));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+3), z_end_spd/60);
        %Final move away:
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',Tool,...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+4));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+4), z_end_spd/60);
        
        %//////////////^Maybe chuck this lot outside for loop
        
    else  %The extrusion is flat and must commence with lights off 
        %For the lasers: there is no reverse phase . . .
        %Currently: the extruder is OFF and the lights are OFF
        Mes2 = ['Path ', num2str(m), ': horizontal extrusion'];
        disp(Mes2)
        
        
   
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_1, sig_spd_4(1));
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_2, sig_spd_4(2));          
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_3, sig_spd_4(3));
        fprintf(fileID,'TIMER T=0.20\r\n');
       
        if strcmp(Interrupt,'OFF') == 1
            Interrupt = 'ON';
        else
            Interrupt = 'OFF';
        end
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n', Interrupt_out, Interrupt);
        %The extruder is now going at ext_speed_4
        %And the lights stay off . . .
        
        for p = 1 : N_rows_per_path(m)-1
            fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n', Tool,...
                Tool_pose_ALL{m}(p+1, 1));
            fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',...
                Tool_pose_ALL{m}(p+1, 1), Tool_pose_ALL{m}(p+1, 9));
        end
    
        
        %//////////////////////////////////////////////////////////////
        %Retract extruder . . .
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_1, sig_spd_7(1));
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_2, sig_spd_7(2));
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n',...
            Extruder_spd_out_3, sig_spd_7(3));
        
        if strcmp(Interrupt,'OFF') == 1
            Interrupt = 'ON';
        else
            Interrupt = 'OFF';
        end
        fprintf(fileID,'TIMER T=0.20\r\n');
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n', Interrupt_out, Interrupt);
        
        fprintf(fileID,'TIMER T=%.2f\r\n',Retraction_time_ALL(m));
        %^^Wait while retraction occurs^^
        %//////////////////////////////////////////////////////////////
        
        %Turn off extruder at last N point . . .
        fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Extruder_spd_out_1);
        fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Extruder_spd_out_2);
        fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Extruder_spd_out_3);
        fprintf(fileID,'TIMER T=0.20\r\n');
        %Tell the arduino that there is a signal . . .
        if strcmp(Interrupt,'OFF') == 1
            Interrupt = 'ON';
        else
            Interrupt = 'OFF';
        end
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n', Interrupt_out, Interrupt);
        
        %Then we execute the Tool_ends with the lights still OFF
        %Raise above N pt (Move to below the nozzle) . . .
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n', Tool,...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+1));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+1), Raise_speed/60);
        
        
 
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',...
            Tool,(Tool_pose_ALL{m}(N_rows_per_path(m),1)+2));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+2), UV_move_speed/60);
        
        %Move into the UV box
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',Tool,...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+3));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+3), UV_move_speed/60);
        
        
        if m == No_horizontal_paths
            %Turn LED lights ON >> delay >> Turn lights OFF
            fprintf(fileID, 'DOUT OT#(%d) ON\r\n', LEDs_out);
            fprintf(fileID,'TIMER T=%.2f\r\n', UVBox_delay);
            fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', LEDs_out);
        end
        %Else we just do stupid moves with the lights off
        
        %Move back to underneath the UV box
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',Tool,...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+4));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',...
            (Tool_pose_ALL{m}(N_rows_per_path(m),1)+4), UV_move_speed/60);
    end
    
    %Else:
    %Have no timer, keep the lights on and extruder off, then only
    %turn the lights OFF after doing the TOOL_end moves
    
end

%Revert back to bed tool
fprintf(fileID, 'SETTOOL TL#(%d) P0000\r\n', Tool);
fprintf(fileID,'END\r\n');
fclose(fileID);

disp('       ')
end

