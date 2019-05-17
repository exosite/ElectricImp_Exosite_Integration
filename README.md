# Exosite (WORK IN PROGRESS REPOSITORY)
This library provides integration with [Exosite](https://exosite.com/) by wrapping the [Exosite HTTPS Device API](http://docs.exosite.com/reference/products/device-api/http/).

**To use this library, add** `#require "Exosite.agent.lib.nut:1.0.0"` **to the top of your agent code.**

  * [What this does (Stage 1)](#what-this-does-stage-1)
  * [What this does not do (yet)](#what-this-does-not-do-yet)
  * [General Usage](#general-usage)
     * [On the device](#on-the-device)
     * [In the agent](#in-the-agent)
  * [Variable Settings](#variable-settings)
     * [debugMode](#debugmode)
     * [configIORefreshTime](#configiorefreshtime)
  * [Available Functions](#available-functions)
     * [Constructor Exosite(<em>productId, deviceId</em>)](#constructor-exositeproductid-deviceid)
     * [provision()](#provision)
     * [writeData(<em>table</em>)](#writedatatable)

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
The following is general pseudo-code usage. \
For a more complete example of usage, see Example/example.agent.nut and Example/example.device.nut


### On the device
```
data.var1 <- getVar1();
data.var1 <- getVar2();

agent.send(“reading.sent”, data);
```

### In the agent
```
Require “Exosite.agent.lib.nut.1.0.0”

const PRODUCT_ID = <my_product_id>;

exositeAgent <- Exosite(PRODUCT_ID, null);
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
The agent periodically checks the config_io set on the server. The length of time between checks can be set with the `configIORefreshTime` variable. By default, the agent waits 60 seconds before refreshing the config_io.
```
exositeAgent.configIORefreshTime = 10;
```

## Available Functions
### Constructor Exosite(*productId, deviceId*) ###
| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| productId | string | yes | The Exosite product ID, this can be found in Exosite's Murano.
| deviceId | string |  no | The name/ID of the device, this needs to be unique for each device within a product.

**Returns** \
Nothing

**Example**
```
local productId = "<Murano Product ID>";

exositeAgent <- Exosite(productId, null);
```

### provision() ###
Provisions the device with Exosite's Murano platform using the information provided in the constructor.

**Returns** \
Nothing

### writeData(*table*) ###
| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| table | table object | yes | Table to be written to data\_in. Each key should match a channel identifier in the config\_io |

For more information on data_in and config_io, checkout the [ExoSense Documentation on Channel Configuration](https://exosense.readme.io/docs/channel-configuration)

**Example Usage**
```
device.on("reading.sent", exositeAgent.writeData.bindenv(exositeAgent));
```
