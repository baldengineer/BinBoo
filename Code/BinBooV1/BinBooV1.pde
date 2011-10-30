

/*
*
 *  BinBooV1
 *  Created by:  James C Lewis.  byerly0503@gmail.com 
 *  www.cmiyc.com
 
 *
 * BinBoo is a Binary clock made out of bamboo materials.  The electrical hardware includes
 a ATmega328, DS1307 RTC, and a TLC5940.  These chips are connected to 11 LEDs.
 *
 *
 * from bash:  date +%s (for number of seconds)
 CDT offset: -18000
 CST offset: -21600
 */

#include <Time.h>  
#include <Wire.h>  
#include <DS1307RTC.h> 
#include <Tlc5940.h>

#define EPOCH_OFFSET -18000
#define TIME_MSG_LEN   11
#define TIME_HEADER 'T'
#define TIME_REQUEST 7
#define WAIT_INTERVAL 5000

#define MAX_BRITE 1024

unsigned long waitMillis;


void setup() {
  Serial.begin(9600);
  Serial.println("BinBoo Release 0.1");

  setSyncProvider(RTC.get);  // grab time from the RTC
  if(timeStatus()!= timeSet) 
    Serial.println("Unable to sync with the RTC");  // not really sure who is going to see this one.. ;)
  else
    Serial.println("RTC has set the system time");  

  Tlc.init();
  Tlc.clear();
  Tlc.update();

  waitMillis = millis() + 1000;   // setup first crossing point
  startUpSequence();
}



void loop() {
  if (Serial.available())
    processSyncMessage();

  if ((long)(millis() - waitMillis) >= 0) {     // need to cast to signed math...
    printTime();
    Serial.print(" ");
    printDate();
    Serial.println();  
    Serial.print("Binary: ");
    Serial.println(calculateTimeBits(), BIN);
    setTLCtime(calculateTimeBits());

    waitMillis += WAIT_INTERVAL;  //sit around for another second.
  }
}

void setTLCtime(int timeStamp ) {
  for (int i=0; i<11; i++) {
    if (bitRead(timeStamp, i))
      Tlc.set(i, MAX_BRITE);
    else
      Tlc.set(i, 0);
  }
  Tlc.update();
}

void startUpSequence() {
  for (int j=0; j<11; j++) {
    Tlc.clear();
    for (int i=0; i<(MAX_BRITE+1); i=i+32) {
      Tlc.set(j, i);
      Tlc.update();
      delay(10);
    }
    for (int i=MAX_BRITE; i > 0; i=i-32) {
      Tlc.set(j,i);
      Tlc.update();
      delay(10);
    }

  }
}

void processSyncMessage() {
  // if time sync available from serial port, update time and return true
  if (Serial.available() >=  TIME_MSG_LEN ) {  // time message consists of a header and ten ascii digits
    char c = Serial.read() ; 

    if( c == TIME_HEADER ) {       
      Serial.print(c);  
      time_t pctime = 0;
      for(int i=0; i < TIME_MSG_LEN -1; i++){   
        c = Serial.read();          
        if( c >= '0' && c <= '9'){   
          pctime = (10 * pctime) + (c - '0'); // convert digits to a number    
        }
      }   
      pctime = pctime EPOCH_OFFSET;  // the define has a math sign in it
      Serial.print(" - ");
      Serial.println(pctime);
      RTC.set(pctime);
      setTime(pctime);   // Sync Arduino clock to the time received on the serial port
      waitMillis += 100;
    }  
  }
}

int calculateTimeBits() {
  int hours = hourFormat12();
  int minutes = minute();
  int timeLEDs=0;

  timeLEDs = hours;
  timeLEDs = hours << 6;

  timeLEDs += minutes;

  if (isPM())
    bitSet(timeLEDs, 10);

  return timeLEDs;
}

void printTime() {
  Serial.print(hourFormat12());
  printDigits(minute());
  printDigits(second());
  Serial.print(" ");
  if (isAM())
    Serial.print("AM");
  else
    Serial.print("PM");
}

void printDate() {
  Serial.print(month());
  Serial.print("/");
  Serial.print(day());
  Serial.print("/");
  Serial.print(year()); 
}

void printDigits(int digits){
  // utility function for digital clock display: prints preceding colon and leading 0
  Serial.print(":");
  if(digits < 10)
    Serial.print('0');
  Serial.print(digits);
}


/*****
 * Routines required:
 * - Input from Serial
 * - Set the RTC
 * - send current time to TLC5940
 * - fetch times from RTC
 * 
 */







