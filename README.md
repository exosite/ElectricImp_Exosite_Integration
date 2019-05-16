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
On the device
```
data.var1 <- get_var1();
data.var1 <- get_var2();

agent.send(“reading.sent”, data);
```

In the agent
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
debug\_mode \
config\_io\_refresh\_time \

## Available Functions
