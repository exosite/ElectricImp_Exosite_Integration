// MIT License

// Copyright 2019 Exosite

// SPDX-License-Identifier: MIT

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

// example.device.nu
// This is example code for the device intended to be used with the impExplorer Development Kit

#require "HTS221.device.lib.nut:2.0.1"
#require "LPS22HB.device.lib.nut:2.0.0"
#require "WS2812.class.nut:3.0.0"

// Define constants
const SLEEP_TIME = 10;

// Declare Global Variables
tempSensor <- null;
pressureSensor <- null;
led <- null

// Define functions
function takeReading(){
  local conditions = {};
  local reading = tempSensor.read();
  conditions.temp <- reading.temperature;
  conditions.humid <- reading.humidity;
  reading = pressureSensor.read();
  conditions.press <- reading.pressure;
 
  // Send 'conditions' to the agent
  agent.send("reading.sent", conditions);

  // Flash the LED
  flashLed();

  // Set the imp to sleep when idle, ie. program complete
  imp.wakeup(SLEEP_TIME, takeReading);
}

function flashLed() {
  led.set(0, [0,0,128]).draw();
  imp.sleep(0.5);
  led.set(0, [0,0,0]).draw();
}

// Start of program

// Configure I2C bus for sensors
local i2c = hardware.i2c89;
i2c.configure(CLOCK_SPEED_400_KHZ);

tempSensor = HTS221(i2c);
tempSensor.setMode(HTS221_MODE.ONE_SHOT);

pressureSensor = LPS22HB(i2c);
pressureSensor.softReset();

// Configure SPI bus and powergate pin for RGB LED
local spi = hardware.spi257;
spi.configure(MSB_FIRST, 7500);
hardware.pin1.configure(DIGITAL_OUT, 1);
led <- WS2812(spi, 1);

// Start Reading Loop
takeReading();

