# Exosite
This library provides integration with [Exosite](https://exosite.com/iot-solutions/condition-monitoring/) by wrapping the [Exosite HTTPS Device API](http://docs.exosite.com/reference/products/device-api/http/).

**To use this library, add** `#require "Exosite.agent.lib.nut:1.0.0"` **to the top of your agent code.**

  * [What this does](#what-this-does)
  * [General Usage](#general-usage)
     * [On the device](#on-the-device)
     * [In the agent](#in-the-agent)
  * [Variable Settings](#variable-settings)
     * [debugMode](#debugmode)
     * [configIORefreshTime](#configiorefreshtime)
  * [Available Functions](#available-functions)
     * [Constructor Exosite(<em>mode, settings</em>)](#constructor-exositemode-settings)
     * [provision()](#provision)
     * [writeData(<em>table</em>)](#writedatatable)
  * [Modes](#modes)
     * [MuranoProduct](#muranoproduct)
  * [Troubleshooting](#troubleshooting)
     * [Authorization Issues](#authorization-issues)

## What this does
Provides an API wrapper to create/provision a device\
Provides an API wrapper for the data_in signal
- [x] Provision (via token auth)
- [x] Write Data
- [x] Acknowledge config_io write

## General Usage
The following is general pseudo-code usage. \
For a more complete example of usage, see Example/example.agent.nut and Example/example.device.nut

### On the device
```
data.var1 <- getVar1();
data.var2 <- getVar2();

agent.send(“reading.sent”, data);
```

### In the agent
```
#require "Exosite.agent.lib.nut:1.0.0"

const PRODUCT_ID = <my_product_id>;
local settings = {};
settings.productId <- PRODUCT_ID;

exositeAgent <- Exosite("MuranoProduct", settings);
exositeAgent.provision();

device.on("reading.sent", exositeAgent.writeData.bindenv(exositeAgent));
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
`configIORefreshTime` is the length (in milliseconds) of the long poll timeout between checking for a new config\_io. \
`configIORefreshTime` defaults to 1500000. User beware, having this too low will cause a 429 error, and cascade issues.

```
exositeAgent.debugMode = 1500000;
```

## Available Functions
### Constructor Exosite(*mode, settings*) ###
| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| mode | string | yes | The mode to execute the library in. [Descriptions of modes are listed below.](#modes).
| settings | table | yes | A table of settings for the corresponding mode selected.

**Returns** \
Nothing

**Example**
```
const PRODUCT_ID = <my_product_id>;
local settings = {};
settings.productId <- PRODUCT_ID;

exositeAgent <- Exosite("MuranoProduct", settings);
```

### provision() ###
Provisions the device with ExoSense using the information provided in the constructor.

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

## Modes ##
There are different modes that can be used with this library. Supported/Released modes are described below.
### MuranoProduct ###
**Usage** \
The `"MuranoProduct"` mode should be selected when a user has their own Murano Product to add their device to.

**Settings**

| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| productId | string | yes | The Murano Product ID to connect and send data to | 
| deviceId  | string | no  | The Device ID to provision as. If not provided, the Electric Imp agent ID will be used. This must be unique between devices in the product. |

**Example Settings**

```
local settings = {};
settings.productId = "c449gfcd11ky00002";
settings.deviceId  = "device0001";
```

## Troubleshooting ##
To assist in troubleshooting, ensure [debugMode](#debugmode) is enabled on the agent. The debug log will viewable be in impCentral.

### Authorization Issues ###
If you are recieving 401 Unauthorized error responses. The Auth token may be out of sync with the Exosite Product.

** Solution **
To mitigate this issue, clear the saved token in the agent, and reprovision the device using the steps below.

1.) Save current agent code \
2.) Clear the agent's token 
  * Paste the contents of clearTable.agent.nut into the Agent code in impCentral. 
  * Commit and run the agent code. \
  
3.) Delete the device from Murano \
4.) Reprovision the device by executing provision() on the Exosite Library



