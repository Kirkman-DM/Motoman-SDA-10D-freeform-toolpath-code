  /*Speed definition: for 3-bits
    0 0 0    0    OFF
    0 0 1    1    Priming
    0 1 0    2    Joining
    0 1 1    3    Extrusion (1)
    1 0 0    4    Extrusion (2)
    1 0 1    5    Extrusion (3)
    1 1 0    6    Extrusion (4)
    1 1 1    7    Reverse
  */
  
  //Robot outputs:
  //OT#(33) for Interrupt_pin
  //OT#(34 - 36) 3-bit extruder speed control

  
  #include <math.h>
  
  #define X_STP                   2     //Reserved
  #define Interrupt_pin           3     //33                      
  #define Extruder_ctrl_pin_1     4     //34                     
  #define X_DIR                   5     //Reserved
  #define Extruder_ctrl_pin_2     6     //35
  #define Extruder_ctrl_pin_3     7     //36
  #define EN                      8     //Reserved               
  //Define system inputs here . . .
  ////////////////////////////////////////////////////////////////
  //7 extrusion speeds . . . first speed is zero (3-bit)
  float ext_speed_1 = 1050;                             //Set         //Priming mm/min
  float ext_speed_2 = 2100;                             //Rev         //Joining
  float ext_speed_3 = 360;                              //Prime       //Extrusion (1)
  float ext_speed_4 = 180;                              //Extrude     //Extrusion (2)
  float ext_speed_5 = 1050;                             //Retract     //Extrusion (3)
  float ext_speed_6 = 120;                              //Horizontal  //Extrusion (4)
  float ext_speed_7 = 120;                              //Free 
  ////////////////////////////////////////////////////////////////
  float Plunger_dia = 12.4;        //Still using 5 mL syringe for now . . . 
  float Nozzle_dia =  3.0;       
  ////////////////////////////////////////////////////////////////
  float pitch = 1;                                      //Extruder:  for M6 threaded bar
  float Step_per_rev = 200;                             //Extruder motor: for 1.8 deg/step motor
  int microstep = 16;                                   //Extruder driver: for 1/16th micro stepping
  volatile boolean direc = true;                        //true == CCW to push the pusher
  ////////////////////////////////////////////////////////////////
 
  //External inputs from CN307 on robot (used in ISR >> volatile):
  volatile byte Speed_in_1 = LOW;
  volatile byte Speed_in_2 = LOW;
  volatile byte Speed_in_3 = LOW;
  volatile byte stepperOn = LOW;                        //Initially start with motor off
  ////////////////////////////////////////////////////////////////
  //For speed calcs:
  volatile float delayTime = 0;
  //Speed 1: set
  float linSpd_1 = 0;                                   //mm/min
  float mot_spd_rev_1 = 0;                              //rev/s
  float mot_spd_stp_1 = 0;                              //steps/s
  float driver_pulses_per_s_1 = 0;                      //pulses/s
  float pulseGap_1 = 0;                                 //s
  volatile float delayTime_1 = 0;                       //pulseGap in micros
  float tot_Time_1 = 0;                                 //s
  
  //Speed 2: reverse
  float linSpd_2 = 0;
  float mot_spd_rev_2 = 0;
  float mot_spd_stp_2 = 0;
  float driver_pulses_per_s_2 = 0;
  float pulseGap_2 = 0;
  volatile float delayTime_2 = 0;
  float tot_Time_2 = 0;
  
  //Speed 3: prime
  float linSpd_3 = 0;
  float mot_spd_rev_3 = 0;
  float mot_spd_stp_3 = 0;
  float driver_pulses_per_s_3 = 0;
  float pulseGap_3 = 0;
  volatile float delayTime_3 = 0;
  float tot_Time_3 = 0;
  
  //Speed 4:extrusion
  float linSpd_4 = 0;
  float mot_spd_rev_4 = 0;
  float mot_spd_stp_4 = 0;
  float driver_pulses_per_s_4 = 0;
  float pulseGap_4 = 0;
  volatile float delayTime_4 = 0;
  float tot_Time_4 = 0;
  
  //Speed 5: retract
  float linSpd_5 = 0;
  float mot_spd_rev_5 = 0;
  float mot_spd_stp_5 = 0;
  float driver_pulses_per_s_5 = 0;
  float pulseGap_5 = 0;
  volatile float delayTime_5 = 0;
  float tot_Time_5 = 0;
  
  //Speed 6: horizontal
  float linSpd_6 = 0;
  float mot_spd_rev_6 = 0;
  float mot_spd_stp_6 = 0;
  float driver_pulses_per_s_6 = 0;
  float pulseGap_6 = 0;
  volatile float delayTime_6 = 0;
  float tot_Time_6 = 0;
  
  //Speed 7: free
  float linSpd_7 = 0;
  float mot_spd_rev_7 = 0;
  float mot_spd_stp_7 = 0;
  float driver_pulses_per_s_7 = 0;
  float pulseGap_7 = 0;
  volatile float delayTime_7 = 0;
  float tot_Time_7 = 0;
  
  //////////////////////////////////////////////////////////
  
  void ISR_1() {
    //Serial.println("Interrupt triggered");
    Speed_in_1 = digitalRead(Extruder_ctrl_pin_1);           //Pin 4, DOUT 34
    Speed_in_2 = digitalRead(Extruder_ctrl_pin_2);           //Pin 6, DOUT 35
    Speed_in_3 = digitalRead(Extruder_ctrl_pin_3);           //Pin 7, DOUT 36
    
    //OFF loop
    if ((Speed_in_1 == LOW) && (Speed_in_2 == LOW) && (Speed_in_3 == LOW)) {
      stepperOn = LOW;
      //No delaytime required as stepper loop will ot be entered
      //Serial.println("Motor is off");
    }
  
    //Set loop
    if ((Speed_in_1 == LOW) && (Speed_in_2 == LOW) && (Speed_in_3 == HIGH)) {
      direc = true;
      digitalWrite(X_DIR, HIGH); //Motor pushes
      stepperOn = HIGH;
      delayTime = delayTime_1;
      //Serial.println("Speed 1 engaged . . .");
    }
  
    //Rev loop
    if ((Speed_in_1 == LOW) && (Speed_in_2 == HIGH) && (Speed_in_3 == LOW)) {
      direc = false;
      digitalWrite(X_DIR, LOW); //Motor pulls
      stepperOn = HIGH;
      delayTime = delayTime_2;
      //Serial.println("Speed 2 engaged . . .");
    }
  
    //Prime loop
    if ((Speed_in_1 == LOW) && (Speed_in_2 == HIGH) && (Speed_in_3 == HIGH)) {
      direc = true;
      digitalWrite(X_DIR, HIGH); //Motor pushes
      stepperOn = HIGH;
      delayTime = delayTime_3;
      //Serial.println("Speed 3 engaged . . .");
    }
  
    //Extrusion loop
    if ((Speed_in_1 == HIGH) && (Speed_in_2 == LOW) && (Speed_in_3 == LOW)) {
      direc = true;
      digitalWrite(X_DIR, HIGH); //Motor pushes
      stepperOn = HIGH;
      delayTime = delayTime_4;
      //Serial.println("Speed 4 engaged . . .");
    }
  
    //Retraction loop
    if ((Speed_in_1 == HIGH) && (Speed_in_2 == LOW) && (Speed_in_3 == HIGH)) {
      direc = false;
      digitalWrite(X_DIR, LOW); //Motor pushes
      stepperOn = HIGH;
      delayTime = delayTime_5;
      //Serial.println("Speed 5 engaged . . .");
    }
  
    //Horizontal loop
    if ((Speed_in_1 == HIGH) && (Speed_in_2 == HIGH) && (Speed_in_3 == LOW)) {
      direc = true;
      digitalWrite(X_DIR, HIGH); //Motor pushes
      stepperOn = HIGH;
      delayTime = delayTime_6;
      //Serial.println("Speed 6 engaged . . .");
    }
  
    //Free loop
    if ((Speed_in_1 == HIGH) && (Speed_in_2 == HIGH) && (Speed_in_3 == HIGH)) {
      direc = true;
      digitalWrite(X_DIR, HIGH); //Motor Pushes
      stepperOn = HIGH;
      delayTime = delayTime_7;
      //Serial.println("Speed 7 . . .");
    }
  }//End of ISR
/////////////////////////////////////////////////////////////
  
  void setup() {
    pinMode(Interrupt_pin, INPUT);
    attachInterrupt(digitalPinToInterrupt(Interrupt_pin), ISR_1, CHANGE);
    pinMode(X_DIR, OUTPUT);
    digitalWrite(X_DIR, HIGH); //Motor pushes
    pinMode(X_STP, OUTPUT);
    pinMode(EN, OUTPUT);
    digitalWrite(EN, LOW);
    //Serial.begin(9600);
    //For verification:
    //Serial.println("Ready");
    //For Robot controller interrupt
    pinMode(Extruder_ctrl_pin_1, INPUT);
    pinMode(Extruder_ctrl_pin_2, INPUT);
    pinMode(Extruder_ctrl_pin_3, INPUT);
    //CALCULATIONS: placed in setup (only performed once)
  
    //Speed 1: priming
    linSpd_1 = ext_speed_1 * (sq(Nozzle_dia / Plunger_dia));         //ext_Spd specified above . . .
    mot_spd_rev_1 = linSpd_1 / 60 * pitch;                           //Convert linSpd from mm/min to mm/s
    mot_spd_stp_1 = mot_spd_rev_1 * Step_per_rev;                    //Multiply by motor steps per rev
    driver_pulses_per_s_1 = mot_spd_stp_1 * microstep;               //Multiply by microstepping mode
    pulseGap_1 = 1 / driver_pulses_per_s_1;                          //to get pulses per sec
    tot_Time_1 = 1000000 * pulseGap_1;                               //Measured in micro seconds . . .
    delayTime_1  = tot_Time_1 * 0.5;
  
    //Speed 2: joining
    linSpd_2 = ext_speed_2 * (sq(Nozzle_dia / Plunger_dia));
    mot_spd_rev_2 = linSpd_2 / 60 * pitch;
    mot_spd_stp_2 = mot_spd_rev_2 * Step_per_rev;
    driver_pulses_per_s_2 = mot_spd_stp_2 * microstep;
    pulseGap_2 = 1 / driver_pulses_per_s_2;
    tot_Time_2 = 1000000 * pulseGap_2;
    delayTime_2  = tot_Time_2 * 0.5;
  
    //Speed 3: extrusion(1)
    linSpd_3 = ext_speed_3 * (sq(Nozzle_dia / Plunger_dia));
    mot_spd_rev_3 = linSpd_3 / 60 * pitch;
    mot_spd_stp_3 = mot_spd_rev_3 * Step_per_rev;
    driver_pulses_per_s_3 = mot_spd_stp_3 * microstep;
    pulseGap_3 = 1 / driver_pulses_per_s_3;
    tot_Time_3 = 1000000 * pulseGap_3;
    delayTime_3  = tot_Time_3 * 0.5;
  
    //Speed 4: extrusio(2)
    linSpd_4 = ext_speed_4 * (sq(Nozzle_dia / Plunger_dia));
    mot_spd_rev_4 = linSpd_4 / 60 * pitch;
    mot_spd_stp_4 = mot_spd_rev_4 * Step_per_rev;
    driver_pulses_per_s_4 = mot_spd_stp_4 * microstep;
    pulseGap_4 = 1 / driver_pulses_per_s_4;
    tot_Time_4 = 1000000 * pulseGap_4;
    delayTime_4  = tot_Time_4 * 0.5;
  
    //Speed 5: extrusion (3)
    linSpd_5 = ext_speed_5 * (sq(Nozzle_dia / Plunger_dia));
    mot_spd_rev_5 = linSpd_5 / 60 * pitch;
    mot_spd_stp_5 = mot_spd_rev_5 * Step_per_rev;
    driver_pulses_per_s_5 = mot_spd_stp_5 * microstep;
    pulseGap_5 = 1 / driver_pulses_per_s_5;
    tot_Time_5 = 1000000 * pulseGap_5;
    delayTime_5 = tot_Time_5 * 0.5;
  
    //Speed 6: extrusio(4)
    linSpd_6 = ext_speed_6 * (sq(Nozzle_dia / Plunger_dia));
    mot_spd_rev_6 = linSpd_6 / 60 * pitch;
    mot_spd_stp_6 = mot_spd_rev_6 * Step_per_rev;
    driver_pulses_per_s_6 = mot_spd_stp_6 * microstep;
    pulseGap_6 = 1 / driver_pulses_per_s_6;
    tot_Time_6 = 1000000 * pulseGap_6;
    delayTime_6  = tot_Time_6 * 0.5;
  
    //Speed 7: reverse
    linSpd_7 = ext_speed_7 * (sq(Nozzle_dia / Plunger_dia));
    mot_spd_rev_7 = linSpd_7 / 60 * pitch;
    mot_spd_stp_7 = mot_spd_rev_7 * Step_per_rev;
    driver_pulses_per_s_7 = mot_spd_stp_7 * microstep;
    pulseGap_7 = 1 / driver_pulses_per_s_7;
    tot_Time_7 = 1000000 * pulseGap_7;
    delayTime_7  = tot_Time_7 * 0.5;
  
  }  //END of void SETUP
  
  void loop() {
  
    if (stepperOn == HIGH) {
  
      digitalWrite(X_STP, HIGH);
      delayMicroseconds(delayTime);
      digitalWrite(X_STP, LOW);
      delayMicroseconds(delayTime);
  
      digitalWrite(X_STP, HIGH);
      delayMicroseconds(delayTime);
      digitalWrite(X_STP, LOW);
      delayMicroseconds(delayTime);
    }
  
  }

