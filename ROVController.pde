import procontroll.*;
import processing.serial.*;
import java.io.*;
import java.util.Scanner;

ControllIO controll;
ControllDevice device;
Serial port;

ControllSlider sliderY;
ControllSlider sliderX;
ControllSlider sliderElev;
ControllSlider sliderRot;

int motorleft = 0; //throttle of left motor
int motorright = 0; //throttle of right motor
int motorelev = 0; //throttle of elevation motor
int motorlat = 0; //throttle of lateral motor

float x, y, r, e; //controller values
long lastSend; //last millisecond to send message to Arduino
PFont bigfont;
PImage ping;

boolean jsError = true;
boolean commsError = true;

void setup(){
  size(1000, 1000);
  
  controll = ControllIO.getInstance(this);
  if (Serial.list().length < 1) {
     println("No Arduinos detected!");
  }
  else if (Serial.list().length > 1) {
     println("Multiple serial interfaces detected!"); 
  }
  else {
    port = new Serial(this, Serial.list()[0], 9600);
    commsError = false;
  }
  
  for (int i = 0; i < controll.getNumberOfDevices(); i++) {
     if (controll.getDevice(i).getName().equals("Logitech Extreme 3D")) { //find actual controller with matching name
        device = controll.getDevice(i);
        jsError = false;
     }
  }
  try {
    device.setTolerance(0.15f); //deadzone
    sliderY = device.getSlider(0);
    sliderX = device.getSlider(1);
    sliderRot = device.getSlider(2);
    sliderElev = device.getSlider(3);
  } catch (Exception e) {
    println("Error while aquiring joystick!"); 
  }
  
  

  bigfont = loadFont("font.vlw");
  
  ping = loadImage("http://i.imgur.com/oJpc87s.png", "png");
  ping.resize(0, 500);
  
  lastSend = millis();
}


void draw(){
  
  //backdrop colors
  fill(191, 144, 46);
  rect(0, 0, width, height/2);
  fill(46, 144, 191);
  rect(0, height/2, width, height/2);
  
  textAlign(CENTER, BOTTOM);
  
  //show background objects
  fill(255);
  rect(100, 100, 255, 255); //stick xy
  rect(100, 400, 255, 50); //rotation bar  
  rect(400, 100, 50, 255); //elevation bar
  
  rect(100, 600, 50, 255); //left motor
  rect(425, 600, 50, 255); //right motor
  rect(160, 900, 255, 50); //lateral motor
  rect(262, 600, 50, 255); //elevation motor
  
  image(ping, width - ping.width, height/2 - ping.height); //draw ping
  
  //show text
  textFont(bigfont, 18);
  
  fill(0,255,0);
  text("TRANS", 227, 100);
  text("ELEV", 425, 100);
  text("ROT", 227, 400);
  text("LEFT", 125, 600);
  text("RIGHT", 450, 600);
  text("ELEV", 287, 600);
  text("LAT", 287, 900);
  
  textFont(bigfont,30);
  fill(0);
  text("CONSOLE", 326, 75);
  text("ROV", 287, 575);
  
  textFont(bigfont, 20);
  text("STATUS", 510, 120);
  if (commsError) {
    fill(255,0,0);
    text("SERIAL", 510, 140);
  }
  else {
    fill(0,255,0);
    text("SERIAL", 510, 140);
  }
  
  if (jsError) {
    fill(255,0,0);
    text("JSTICK", 510, 160);
  }
  else {
    fill(0,255,0);
    text("JSTICK", 510, 160);
  }
  
  try {
    x = sliderX.getValue();
    y = sliderY.getValue();
    r = sliderRot.getValue();
    e = sliderElev.getValue();
    jsError = false;
  }
  catch (Exception e) {
    if (!jsError) {
      jsError = true;
      println("Error while polling joystick values!");
    }
  }
  
  //display joystick x y
  line(227, 227, 227 + x * 127, 227 + y * 127);
  fill(255, 0, 0);
  ellipse(227 + x * 127, 227 + y * 127, 10, 10); 
  
  //display joystick rotation
  rect(227, 400, r * 127,  50); 
  
  //display joystick elevation
  rect(400, 227, 50, e * 127);
  
  //process motor output
  motorleft = (int)constrain((y - r)*127, -127, 127);
  motorright = (int)constrain((y + r)*127, -127, 127);
  motorlat = (int)(x * 127);
  motorelev = (int)(e * 127);
  
  //display motor output
  fill(0, 255, 0);
  rect(100, 727, 50, motorleft);
  rect(425, 727, 50, motorright);
  rect(287, 900, motorlat, 50);
  rect(262, 727, 50, motorelev);
  
  //send motor output
  if ( millis() - lastSend > 100) { //minimum time between msg = 100ms
    lastSend = millis();
    printToArduino(-motorleft,  -motorright,  -motorelev,  motorlat); //negatives for correct polarity
    
    if (commsError) { //if not connected, attempt reconnect
       if (Serial.list().length == 1) {
        port = new Serial(this, Serial.list()[0], 9600);
        commsError = false;
       }
    }
    
  } 
}

void printToArduino(int m1,  int m2,  int m3,  int m4) {
  if (!commsError) {
    m1 += 127;
    m2 += 127;
    m3 += 127;
    m4 += 127;
    port.write('T');
    port.write(hex(m1,2));
    port.write(hex(m2,2));
    port.write(hex(m3,2));
    port.write(hex(m4,2));
  }
}
