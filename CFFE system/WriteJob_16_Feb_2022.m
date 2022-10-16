%Uses a single interrupt on arduino to check all of robot outputs . . .
%NOTE: applies to >>Extrusion moves<< and NOT >>dry moves<<. Speed for dry
%moves can be specified within Matlab code . . . 

%Note: there may be two idential P points at the beginning of the job.
%First is to make sure the extruder starts in the right place. Second is the first toolpath point . . .


function WriteJob_16_Feb_2022(Number_of_paths, N_rows_per_path, Tool_bed, Tool_pose_ALL, JobName, JobFile, dateTime, Tool, Stoppage_delay_ALL,...
                        Tool_end_comb_ALL, Tool_start_ALL, z_end_spd, C_noz_tip, cutter_drop_pin, cutter_engage_pin, Arduino_out_3, LEDs_out, Lasers_out,...
                        Interrupt_out, nr_of_cuts, laser_cut_cure_delay, cutting_delay, pause_delay,...                          %Signals corresponding to each speed
                        Calibration_speed_VJ, Approach_Speed, Inbetween_speed, bump_dist, z_offset_bed, Raise_speed,...
                        UVBox_delay, UV_move_speed, stickage_delay, Re)
                
 %NOTE: N_rows_per_path is a vector, need to extract entries later.                           
                           
                           
%Initialize interrupt variable: 
Interrupt = 'OFF';                                           %Start with interrupt OFF (It is put off at the beginning of the job anyway . . .


%//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
%Header:
    fileID = fopen(JobFile , 'w');                          %Open a text file to which we can write . . .
    fprintf(fileID,'/JOB\r\n');
    fprintf(fileID,'//NAME %s\r\n', JobName);
    fprintf(fileID,'//POS\r\n');
    fprintf(fileID,'///NPOS %d,0,0,%d,0,0\r\n',sum(N_rows_per_path) + 5*Number_of_paths + 1, sum(N_rows_per_path) + 5*Number_of_paths + 1);   %NEEDS CHECKING . . .
    fprintf(fileID,'///TOOL %d\r\n', Tool);
    %For C coordinates: 
    fprintf(fileID,'///POSTYPE ROBOT\r\n');
    fprintf(fileID,'///RECTAN\r\n');
    fprintf(fileID,'///RCONF 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\r\n');  %Check REAR/UP/FLIP 
   
  %//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
  %Write out the nozzle tip points which are repeated . . . 
  
    for k = 1 : (sum(N_rows_per_path) + 5*Number_of_paths) + 1      %1 start tool, 4 end tools, 1 approach point
    fprintf(fileID,'C%05d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n', k - 1, C_noz_tip(1), C_noz_tip(2), C_noz_tip(3), C_noz_tip(4), C_noz_tip(5), C_noz_tip(6), C_noz_tip(7));  
    end 
    
 %Now it gets UGLEEEE :/
       
    %For P points
    fprintf(fileID,'///POSTYPE ROBOT\r\n');
    fprintf(fileID,'///RECTAN\r\n');
    fprintf(fileID,'///RCONF 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0\r\n');         % 0 0 1 OR 1 0 1 ???
    
%Point 0: the >>>bed tool + bump distance<<< is defined here: 

    fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n', 0, Tool_bed(1), Tool_bed(2), Tool_bed(3) + z_offset_bed + bump_dist, Tool_bed(4), Tool_bed(5), Tool_bed(6), Re);              %For the bump point
    
%Then define the rest of the points: Point 1 to point N (first point is
%PT 1 is the first point of the first array . . . 

for d = 1 : Number_of_paths                             %Repeat loop for each path . . .
            %Extract the necessary tool_pose matrix from Tool_pose_ALL
        
            
            %The start tool would go in here:
            fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n', (Tool_pose_ALL{d}(1,1)-1), Tool_start_ALL{d}(1,1), Tool_start_ALL{d}(1,2),Tool_start_ALL{d}(1,3),Tool_start_ALL{d}(1,4),Tool_start_ALL{d}(1,5),Tool_start_ALL{d}(1,6),Tool_start_ALL{d}(1,7));
                      
            for i = 1 : N_rows_per_path(d)                           %There are N Tool poses . . .        
                fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n', Tool_pose_ALL{d}(i,1), Tool_pose_ALL{d}(i,2), Tool_pose_ALL{d}(i,3), Tool_pose_ALL{d}(i,4), Tool_pose_ALL{d}(i,5), Tool_pose_ALL{d}(i,6), Tool_pose_ALL{d}(i,7), Tool_pose_ALL{d}(i,8));
                %^NOTE: P002 contains the first entry of Tool_pose^
            end 
%Then define the final tool (to move away after extrusion)
    %<<<<<<<<<Other 2 end tools here>>>>>>>>>>> may need more C points . .
    fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n', (Tool_pose_ALL{d}(N_rows_per_path(d),1)+1), Tool_end_comb_ALL{d}(1,1), Tool_end_comb_ALL{d}(1,2),Tool_end_comb_ALL{d}(1,3),Tool_end_comb_ALL{d}(1,4),Tool_end_comb_ALL{d}(1,5),Tool_end_comb_ALL{d}(1,6),Tool_end_comb_ALL{d}(1,7));
    fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n', (Tool_pose_ALL{d}(N_rows_per_path(d),1)+2), Tool_end_comb_ALL{d}(2,1), Tool_end_comb_ALL{d}(2,2),Tool_end_comb_ALL{d}(2,3),Tool_end_comb_ALL{d}(2,4),Tool_end_comb_ALL{d}(2,5),Tool_end_comb_ALL{d}(2,6),Tool_end_comb_ALL{d}(2,7));
    fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n', (Tool_pose_ALL{d}(N_rows_per_path(d),1)+3), Tool_end_comb_ALL{d}(3,1), Tool_end_comb_ALL{d}(3,2),Tool_end_comb_ALL{d}(3,3),Tool_end_comb_ALL{d}(3,4),Tool_end_comb_ALL{d}(3,5),Tool_end_comb_ALL{d}(3,6),Tool_end_comb_ALL{d}(3,7));
    fprintf(fileID,'P%04d=%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\r\n', (Tool_pose_ALL{d}(N_rows_per_path(d),1)+4), Tool_end_comb_ALL{d}(4,1), Tool_end_comb_ALL{d}(4,2),Tool_end_comb_ALL{d}(4,3),Tool_end_comb_ALL{d}(4,4),Tool_end_comb_ALL{d}(4,5),Tool_end_comb_ALL{d}(4,6),Tool_end_comb_ALL{d}(4,7));
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%Instruction data
    fprintf(fileID,'//INST\r\n');
    fprintf(fileID,'///DATE %s\r\n', dateTime);         %May cause issues: 
    fprintf(fileID,'///ATTR SC,RW,RJ\r\n');
    fprintf(fileID,'////FRAME ROBOT\r\n');
    fprintf(fileID,'///GROUP1 RB1\r\n');
    fprintf(fileID,'NOP\r\n');

%Ensure all oututs are off before starting:
    fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Interrupt_out);
    fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', cutter_drop_pin);
    fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', cutter_engage_pin);
    fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Arduino_out_3);
    fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Lasers_out);
    fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', LEDs_out);
    
%Move frome current position to approach position (offset from start position by bump_dist)
    fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n', Tool, 0);                                   %Tool #11 is the bed tool. The bed tool is currently at the nozzle tip . . .
    fprintf(fileID, 'MOVJ C%05d VJ=%.2f\r\n', 0, Calibration_speed_VJ);   
    %Now P000 and C0000 have been used up . . . The next point is the
    %actual start of the extrusion . . . 
    
    
 for m = 1 : Number_of_paths
        %Use the start tool . . .
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n', Tool, (Tool_pose_ALL{m}(1,1)-1));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n', (Tool_pose_ALL{m}(1,1)-1), Approach_Speed);
     
        %Move to the start position
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n', Tool, Tool_pose_ALL{m}(1,1));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n', Tool_pose_ALL{m}(1,1), Inbetween_speed);   %Moving from end of last extrusion to beginning of next extrusion                        

 
     
       
            
        %Pop the lasers on: 
        fprintf(fileID, 'DOUT OT#(%d) ON\r\n', Lasers_out);
        %Continue with lights on:

            %Frist implement the stickage deleay: 
            fprintf(fileID,'TIMER T=%.2f\r\n', stickage_delay);
            %Then carry on once the fiber are stuck on . . . 
        %%%%%%%%%%%%%   Do the main extrusion 
                for k = 1 : N_rows_per_path(m) - 1                                    %The -1 is there since we used k + 1 in the index (pt 1 has already been used. . .                   
                    fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n', Tool, Tool_pose_ALL{m}(k+1, 1));
                    fprintf(fileID, 'MOVL C%05d V=%.2f\r\n', Tool_pose_ALL{m}(k+1, 1), Tool_pose_ALL{m}(k+1, 9));               %Point and speed  . . .
                end
                %We end at point N . . .
        %%%%%%%%%%%%%    

        %Extrude past final point to compensate for setting distance:
        %Pt N + 1 is the first End tool
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n', Tool,(Tool_pose_ALL{m}(N_rows_per_path(m),1)+1));          %The first end tool is used here
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',(Tool_pose_ALL{m}(N_rows_per_path(m),1)+1), Tool_pose_ALL{m}(N_rows_per_path(m), 9));                    %Same speed as last extrusion point . . . assume similar delays etc
        
        
        %Delay after stoppage of motion
        if Stoppage_delay_ALL(m) > 0
            fprintf(fileID,'TIMER T=%.2f\r\n',Stoppage_delay_ALL(m));
        end
        %Turn LASERS off
        fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Lasers_out);
        
   %Execute cutting moves:
        
        %Move to cut-cure point:
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',Tool,(Tool_pose_ALL{m}(N_rows_per_path(m),1)+2));           %Second end tool used here
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',(Tool_pose_ALL{m}(N_rows_per_path(m),1)+2), z_end_spd);
        
        %Flash the lasers on the cut-cure point
        if laser_cut_cure_delay > 0
            fprintf(fileID, 'DOUT OT#(%d) ON\r\n', Lasers_out);
            fprintf(fileID,'TIMER T=%.2f\r\n', laser_cut_cure_delay);
            fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', Lasers_out);
        end
        %Now move up to the cutting point (Tool 3)
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',Tool,(Tool_pose_ALL{m}(N_rows_per_path(m),1)+3));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',(Tool_pose_ALL{m}(N_rows_per_path(m),1)+3), z_end_spd);
        
        %Apply the fiber cutting moves here
        %Drop the cutter into place
        fprintf(fileID, 'DOUT OT#(%d) ON\r\n', cutter_drop_pin);
        %Interrupt for dropping cutter into place:
        if strcmp(Interrupt,'OFF') == 1
            Interrupt = 'ON';
        else
            Interrupt = 'OFF';
        end
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n', Interrupt_out, Interrupt);
        %Give the cutter a moment to drop into place:
        fprintf(fileID,'TIMER T=%.2f\r\n', pause_delay);
        
        %Execute the cut(s)
        cut_record = 0;
        while cut_record < nr_of_cuts
            %Engage cutter motor:
            fprintf(fileID, 'DOUT OT#(%d) ON\r\n', cutter_engage_pin);
            %Interrupt for starting cut
            if strcmp(Interrupt,'OFF') == 1
                Interrupt = 'ON';
            else
                Interrupt = 'OFF';
            end
            fprintf(fileID, 'DOUT OT#(%d) %s\r\n', Interrupt_out, Interrupt);
            %Wait while the cutter executes cut and retracts
            fprintf(fileID,'TIMER T=%.2f\r\n', cutting_delay);
            
            %Interrupt for terminating cut
            cut_record = cut_record + 1;
            
            %And make sure the cutter is off in case this was the last cut
            if cut_record ==  nr_of_cuts         %Then we are about to exit the while loop %else the cutter will re engage next time the interrupt is triggered which is fine for multiple cuts
                fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', cutter_engage_pin);
                %Interrupt for starting cut
                if strcmp(Interrupt,'OFF') == 1
                    Interrupt = 'ON';
                else
                    Interrupt = 'OFF';
                end
                fprintf(fileID, 'DOUT OT#(%d) %s\r\n', Interrupt_out, Interrupt);
            end
        end
        
        
        %Retract the cutter back into place
        fprintf(fileID, 'DOUT OT#(%d) OFF\r\n', cutter_drop_pin);
        
        
        
        %Interrupt for retracting the servo after cutting has occurred:
        %Give the prev signals a bit of time
        fprintf(fileID,'TIMER T=0.500\r\n');
        if strcmp(Interrupt,'OFF') == 1
            Interrupt = 'ON';
        else
            Interrupt = 'OFF';
        end
        fprintf(fileID, 'DOUT OT#(%d) %s\r\n', Interrupt_out, Interrupt);
        
        
        %Execute the final end tool move
        fprintf(fileID, 'SETTOOL TL#(%d) P%04d\r\n',Tool,(Tool_pose_ALL{m}(N_rows_per_path(m),1)+4));
        fprintf(fileID, 'MOVL C%05d V=%.2f\r\n',(Tool_pose_ALL{m}(N_rows_per_path(m),1)+4), z_end_spd);
                    
                                        
    
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
    
