# Exosite (WORK IN PROGRESS REPOSITORY)
This library provides integration with [Exosite](https://exosite.com/) by wrapping the [Exosite HTTPS Device API](http://docs.exosite.com/reference/products/device-api/http/).

**To use this library, add** `#require "Exosite.agent.lib.nut:1.0.0"` **to the top of your agent code.**

## TODO
- [x] Code
- [ ] Unit Tests
- [ ] General QA Tests
- [ ] Add License
- [ ] Add sample code
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
data.var1 <- get_var1();
data.var1 <- get_var2();

agent.send(“reading.sent”, data);
```

### In the agent
```
Require “Exosite.agent.lib.nut.1.0.0”

local product_id = <my_product_id>;
local device_id = <my_device_id>;
local password = <my password>;

exosite_agent <- Exosite(product_id, device_id, password);
exosite_agent.provision();

device.on(“reading.sent”, exosite_agent.write_data.bindenv(exosite_agent));
```

## Variable Settings
Some variables can be changed in the class instance of an Exosite agent. These variables and their effects are listed below.

### debug\_mode
Debug mode logs additional messages to the ElectricImp server for added debugging. \
The debug mode is off (false) by default, and can be enabled by setting `debug_mode` to true.
```
exosite_agent.debug_mode = true;
```
### config\_io\_refresh\_time
The agent periodically checks the config_io set on the server. The length of time between checks can be set with the config_io_refresh_time variable. By default, the agent waits 60 seconds before refreshing the config_io.
```
exosite_agent.config_io_refresh_time = 10;
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
local product_id = "<Murano Product ID>";
local device_id = "my_device_0001";
local password = "123456789ABCabcXYZxyz"";

exosite_agent <- Exosite(product_id, device_id, password);
```

### provision() ###
Provisions the device with Exosite's Murano platform using the information provided in the constructor.

### write\_data(table) ###
| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| table | table object | yes | Table to be written to data\_in. Each key should match a channel identifier in the config\_io |

**Example Usage**
```
device.on("reading.sent", exosite_agent.write_data.bindenv(exosite_agent));
```
