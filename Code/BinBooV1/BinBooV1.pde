/*
 *
 *  BinBooV1
 *  Created by:  James C Lewis.  byerly0503@gmail.com 
 *  www.cmiyc.com
 *
 * BinBoo is a Binary clock made out of bamboo materials.  The electrical hardware includes
 * a ATmega328, DS1307 RTC, and a TLC5940.  These chips are connected to 11 LEDs.
 *
 * from bash:  date +%s (for number of seconds)
 * CDT offset: -18000
 * CST offset: -21600
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

#define DAY_BRITE 512
#define NIGHT_BRITE 128

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
  int previousTime=0;
  int currentTime=0;
  while(1) {      // want to avoid making currentTime/previousTime global
    if (Serial.available())
      processSyncMessage();
    if ((long)(millis() - waitMillis) >= 0) {     // need to cast to signed math...
      printTimeDate();
      currentTime = calculateTimeBits();
       setTLCtime(previousTime, currentTime);
      previousTime = currentTime;
      waitMillis += WAIT_INTERVAL;  //sit around for another second.
    }
  }
}

void setTLCtime(int previousTime, int currentTime ) {

  if (previousTime == currentTime)    // time hasn't changed, so don't do anything
    return;

  int bright = 0;    // what is the max brightness, based on the time.
  if ((hour() >= 6) && (hour() <= 18))
    bright = DAY_BRITE;  
  else
    bright = NIGHT_BRITE;

  for (int i=0; i<=bright; i++) {
    int fadeAmount = 0;  // each look of the bright for, will be to fade up/down the leds
    for (int j=0; j<11; j++) {   // this loop determines which direction and intensity of fade
      switch (bitRead(previousTime, j) - bitRead(currentTime,j)) {
      case 0:  // no change, the led alone
        if bitRead(currentTime,j)
          fadeAmount = bright;
        else
          fadeAmount = 0;
        break;
      case -1: // turn the led on
        fadeAmount = i;
        break;
      case 1: // turn the led off
        fadeAmount = bright - i;
        break;
      }
      Tlc.set(j, fadeAmount);
    }   
    Tlc.update();
    delay(1);
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

void printTimeDate() {
  printTime();
  Serial.print(" ");
  printDate();
  Serial.println("");
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


void startUpSequence() {
  for (int j=0; j<11; j++) {
    Tlc.clear();
    for (int i=0; i<(DAY_BRITE+1); i=i+32) {
      Tlc.set(j, i);
      Tlc.update();
      delay(10);
    }
    for (int i=DAY_BRITE; i > 0; i=i-32) {
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













