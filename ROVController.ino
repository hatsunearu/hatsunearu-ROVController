#include <Servo.h>

Servo mc1;
Servo mc2;
Servo mc3;
Servo mc4;

char buffer[8]; //8 Hexademcimal Inputs, 2 (a signed byte) per motor channel

void setup() {

        mc1.attach(2);
        mc2.attach(3);
        mc3.attach(4);
        mc4.attach(5);
        
        mc1.writeMicroseconds(1500);
        mc2.writeMicroseconds(1500);
        mc3.writeMicroseconds(1500);
        mc4.writeMicroseconds(1500);
        Serial.begin(9600);
}

void loop() {
  while(Serial.available() > 0) {
     
        byte message = Serial.read();

        if (message == 'T' || message == 't') { //Throttle message starts with T followed by 8 Hexadecimal inputs
                delay(10); //wait for arrival of bytes to hardware buffer
                for(int i=0; i < 8; i++) {
                        
                        buffer[i] = Serial.read();
                        delay(1);
                        //Serial.println(i);
                        //Serial.println((int)buffer[i]);
                }       

                //Convert two hexes to a decimal 0~255, rescale to 905 ~ 2100
                //center value is 127
                mc1.writeMicroseconds( 75 * (hex2dec(buffer[0]) * 16 + hex2dec(buffer[1])) / 16 + 905 );
                mc2.writeMicroseconds( 75 * (hex2dec(buffer[2]) * 16 + hex2dec(buffer[3])) / 16 + 905 );
                mc3.writeMicroseconds( 75 * (hex2dec(buffer[4]) * 16 + hex2dec(buffer[5])) / 16 + 905 );
                mc4.writeMicroseconds( 75 * (hex2dec(buffer[6]) * 16 + hex2dec(buffer[7])) / 16 + 905 );
        }
        
        else {
           Serial.flush(); 
        }

  }
} 

byte hex2dec(byte c) {
        if (c >= '0' && c <= '9') {
                return c - '0';
        }       
        else if (c >= 'A' && c <= 'F') {
                return c - 'A' + 10;
        }       
        else if (c >= 'a' && c <= 'f') {
                return c - 32 - 'A' + 10;
        }       
}
