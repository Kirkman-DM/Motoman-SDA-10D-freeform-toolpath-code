//NOTES:
/*Input pins:
   33 -> Robot interrupt 
   34 -> Drop cutter (if not UP, then cutter is raised)
   35 -> Engage cutter
   36 -> Open for now
   37 -> LASERS (DO NOT ENGAGE UNLESS PROTECTED)
   38 -> UV box
*/

//Libraries
#include <Servo.h>

//Define input and output pins:
//Input pins
#define robot_interrupt_pin       3     //33
#define cutter_drop_pin           4     //34
#define cutter_engage_pin         6     //35
#define force_switch_pin          9     //Limit x axis
//Output pins
#define swingarm_ctrl_pin         10    //Output pin to control swingarm >> limit y axis 
#define cutter_ctrl_pin           11    //Output pin to control cutter  >> limit z axis 

//define the 2 servo motors:
Servo swingArm;
Servo cutterMotor;

//Define the fixed variables/////////////////////////////////////////////////
//Define the 2 swingarm positions:
int pos_up = 150;    //Retracted position
volatile int pos_down_1 = 38;   //Activated position
volatile int pos_down_2 = 43;
volatile int pos_down = 0;
volatile int no_cuts = 1;
//Define the forward, reverse and rest speeds of the cutter
int cutter_spd_closing = 180;
int cutter_spd_opening = 0;      //Correspnding actual speed value is 3.82 rad/s
int act_cut_spd_opening = 3.82;  //(rad/s) Must be updated based on above value and the graph
int cutter_spd_stop = 90;
//Define the initial values of the input variables
volatile byte cutter_drop = LOW;
volatile byte cutter_raise = LOW;
volatile byte cutter_engage = LOW;
volatile byte force_switch = HIGH;
//Define the parameters for the opening delay
float open_dist = 35;           //(mm) Distance which handles open at point where guitar string is.
float cutter_pulley_dia = 11;   //(mm)
float opening_angle = 0;        //Pulley rotation angle (to be calculated)
int open_delay = 0;             //Motor ON delay (to be calculated)

///////////////////////////////FUNCTIONS/////////////////////////////////////

void readSignals () {
  //Read the input pins (only happens when the robot interrupt pin is triggered)
  cutter_drop = digitalRead(cutter_drop_pin);
  cutter_engage = digitalRead(cutter_engage_pin);
}

void setup() {
  Serial.begin(9600);
  //ISR setup:
  attachInterrupt(digitalPinToInterrupt(robot_interrupt_pin), readSignals, CHANGE);
  //Servo allocations:
  swingArm.attach(swingarm_ctrl_pin);
  cutterMotor.attach(cutter_ctrl_pin);
  //Pinmodes for inputs:
  pinMode(cutter_drop_pin, INPUT);
  pinMode(cutter_engage_pin, INPUT);
  pinMode(force_switch_pin, INPUT_PULLUP);  //Maybe make this a manual PULLUP later on  . . .//
  //Pinmodes for outputs:
  pinMode(swingarm_ctrl_pin, OUTPUT);
  pinMode(cutter_ctrl_pin, OUTPUT);
  //Initialize the positions / speeds for the servo motors:
  swingArm.write(pos_up);
  cutterMotor.write(cutter_spd_stop);
  //Calculations for the opening delay:
  opening_angle = open_dist/(cutter_pulley_dia/2);    //rad
  open_delay = opening_angle/act_cut_spd_opening;     //(rad/s) see comment on cutter opening speed 
  pos_down  = pos_down_1;
}

void loop() {
  //check on the force limiter switch
  force_switch = digitalRead(force_switch_pin);

  //Act on the readings:
  if (cutter_drop == HIGH) {              //Then we must drop the cutter into position 
    if ((no_cuts % 2) == 1)  {           //Then no of cuts is odd (first, third,  . . . )
        pos_down = pos_down_1;
    }
    else{
      pos_down = pos_down_2;
    }
    swingArm.write(pos_down);     
  }
  else{                                   //The cutter pin is not high, in which case the cutter is retracted 
    swingArm.write(pos_up);
    no_cuts  = 1;                         //reset the cutter counter 
  }

  if (force_switch == LOW && cutter_engage == HIGH) {       //Cutter has already been engaged and switch is triggered (logig inverted) 
    cutterMotor.write(cutter_spd_opening);    //Disengage the cutter 
    cutter_engage = LOW;                 //can't be made HIGH again unless the ISR is triggered . Ensures that the cutter does not re-engage before we tell it to. (Acc to robot cutter_engage is still HIGH) 
    delay(1000*open_delay);                        //Wait while the cutter disengages 
    Serial.println(open_delay);
    cutterMotor.write(cutter_spd_stop);       //Stall the motor when it has retracted sufficiently 
    no_cuts = no_cuts + 1;
  }
  
  if (cutter_engage == HIGH) {
    cutterMotor.write(cutter_spd_closing);    //Engage the cutter 
  }
  else{
    cutterMotor.write(cutter_spd_stop);
  }
}
















