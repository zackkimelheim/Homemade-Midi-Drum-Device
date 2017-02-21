#include <Wire.h>
#include "Adafruit_Trellis.h"

#define MOMENTARY 0
#define LATCHING 1
// set the mode here
#define MODE LATCHING

const int bpmPotPin = A3;
const int colorPotPin = A2;
const int volumePotPin = A1;



Adafruit_Trellis matrix0 = Adafruit_Trellis();

Adafruit_TrellisSet trellis =  Adafruit_TrellisSet(&matrix0);

#define NUMTRELLIS 1

#define numKeys (NUMTRELLIS * 16)

// Connect Trellis Vin to 5V and Ground to ground.
// Connect the INT wire to pin #A2 (can change later!)
#define INTPIN A2
// Connect I2C SDA pin to your Arduino SDA line
// Connect I2C SCL pin to your Arduino SCL line
// All Trellises share the SDA, SCL and INT pin!
// Even 8 tiles use only 3 wires max


void setup() {
  Serial.begin(9600);


  // INT pin requires a pullup
  pinMode(INTPIN, INPUT);
  digitalWrite(INTPIN, HIGH);

  // begin() with the addresses of each panel in order
  // I find it easiest if the addresses are in order
  trellis.begin(0x70);  // only one
  // trellis.begin(0x70, 0x71, 0x72, 0x73);  // or four!

  // light up all the LEDs in order
  for (uint8_t i = 0; i < numKeys; i++) {
    trellis.setLED(i);
    trellis.writeDisplay();
    delay(50);
  }
  // then turn them off
  for (uint8_t i = 0; i < numKeys; i++) {
    trellis.clrLED(i);
    trellis.writeDisplay();
    delay(50);
  }
}


void loop() {
  delay(30); // 30ms delay is required, dont remove me!

  if (millis() % 5 == 0) {
    int bpmPotVal = analogRead(bpmPotPin);

    Serial.print("bpm");
    Serial.print(",");
    Serial.println(bpmPotVal);
  }

  if (millis() % 2 == 0) {
    int colorPotVal = analogRead(colorPotPin);

    Serial.print("color");
    Serial.print(",");
    Serial.println(colorPotVal);
  }

  int volumePotVal = analogRead(volumePotPin);

  if (MODE == MOMENTARY) {
    // If a button was just pressed or released...
    if (trellis.readSwitches()) {
      // go through every button
      for (uint8_t i = 0; i < numKeys; i++) {
        // if it was pressed, turn it on

        if (trellis.justPressed(i)) {


          trellis.setLED(i);
        }
        // if it was released, turn it off
        if (trellis.justReleased(i)) {

          trellis.clrLED(i);
        }
      }
      // tell the trellis to set the LEDs we requested
      trellis.writeDisplay();
    }
  }

  if (MODE == LATCHING) {
    // If a button was just pressed or released...
    if (trellis.readSwitches()) {
      // go through every button
      for (uint8_t i = 0; i < numKeys; i++) {
        // if it was pressed...

        if (trellis.justPressed(i)) {
          Serial.print("button");
          Serial.print(",");
          Serial.println(i);
          // Alternate the LED
          if (trellis.isLED(i)) {
            trellis.clrLED(i);
          }
          else {
            trellis.setLED(i);
          }
        }
      }
      // tell the trellis to set the LEDs we requested
      trellis.writeDisplay();
    }
  }
}
