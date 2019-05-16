# Exosite (WORK IN PROGRESS REPOSITORY)
This library provides integration with [Exosite](https://exosite.com/) by wrapping the [Exosite HTTPS Device API](http://docs.exosite.com/reference/products/device-api/http/).

**To use this library, add** `#require "Exosite.agent.lib.nut:1.0.0"` **to the top of your agent code.**

## TODO
- [x] Code
- [ ] Unit Tests
- [ ] General QA Tests
- [x] Add License
- [x] Add sample code
- [ ] Code Review
- [ ] Release to ElectricImp

## What this does (Stage 1)
Provides an API wrapper to create/provision a device in Murano \
Provides an API wrapper for the data_in signal to Murano
- [x] Provision (via password)
- [x] Write Data



## What this does not do (yet)
Handle 'data_out' from Murano \
Enable configuration via 'config_io'
- [ ] Timestamp
- [ ] Read Data
- [ ] Reprovision
- [ ] List Available Content
- [ ] Get Content Info
- [ ] Download Content
- [ ] Hybrid Read Write
- [ ] Long Polling
- [ ] Record

## General Usage
### On the device
```
data.var1 <- getVar1();
data.var1 <- getVar2();

agent.send(“reading.sent”, data);
```

### In the agent
```
Require “Exosite.agent.lib.nut.1.0.0”

local productId = <my_product_id>;
local deviceId = <my_device_id>;
local password = <my password>;

exositeAgent <- Exosite(productId, deviceId, password);
exositeAgent.provision();

device.on(“reading.sent”, exositeAgent.writeData.bindenv(exositeAgent));
```

## Variable Settings
Some variables can be changed in the class instance of an Exosite agent. These variables and their effects are listed below.

### debugMode
Debug mode logs additional messages to the ElectricImp server for added debugging. \
The debug mode is off (false) by default, and can be enabled by setting `debugMode` to true.
```
exositeAgent.debugMode = true;
```
### configIORefreshTime
The agent periodically checks the config_io set on the server. The length of time between checks can be set with the configIORefreshTime variable. By default, the agent waits 60 seconds before refreshing the config_io.
```
exositeAgent.configIORefreshTime = 10;
```

## Available Functions
### Constructor Exosite(*productId, deviceId, password*) ###
| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| productId | string | yes | The Exosite product ID, this can be found in Exosite's Murano.
| deviceId | string |  yes | The name/ID of the device, this needs to be unique for each device within a product.
| password | string | yes | The associated password with the device.

**Returns** \
Nothing

**Example**
```
local productId = "<Murano Product ID>";
local deviceId = "my_device_0001";
local password = "123456789ABCabcXYZxyz"";

exositeAgent <- Exosite(productId, deviceId, password);
```

### provision() ###
Provisions the device with Exosite's Murano platform using the information provided in the constructor.

### writeData(table) ###
| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| table | table object | yes | Table to be written to data\_in. Each key should match a channel identifier in the config\_io |

**Example Usage**
```
device.on("reading.sent", exositeAgent.writeData.bindenv(exositeAgent));
```
