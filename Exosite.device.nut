#require "HTS221.device.lib.nut:2.0.1"
#require "LPS22HB.device.lib.nut:2.0.0"
#require "WS2812.class.nut:3.0.0"

// Define constants
const SLEEP_TIME = 120;

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
  imp.onidle(function() {
    server.sleepfor(SLEEP_TIME);
  });
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

// Take a reading
local counter = 0;
while (true) {
    takeReading();
    counter = counter+1;
    imp.sleep(2);
}

