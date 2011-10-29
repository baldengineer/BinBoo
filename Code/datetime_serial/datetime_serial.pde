void setup() {
 pinMode(13, OUTPUT); 
 Serial.begin(9600);
 Serial.print("Date: ");
 Serial.println(__DATE__); 
  Serial.print("Time: "); 
  Serial.println(__TIME__); 
  Serial.println();
  Serial.println();
}

void loop() {
 Serial.println(__TIME__);
 digitalWrite(13, !digitalRead(13));
 delay(500); 
}
