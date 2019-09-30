# Exosite #

This library provides integration with [Exosite](https://exosite.com/iot-solutions/condition-monitoring/) by wrapping the [Exosite HTTPS Device API](http://docs.exosite.com/reference/products/device-api/http/).

**To include this library in your project, add** `#require "Exosite.agent.lib.nut:1.0.0"` **at the top of your agent code**

## Contents ##

* [What This Library Does](#what-this-library-does)
* [Pre-requisites](#pre-requisites)
* [General Library Usage](#general-library-usage)
* [Library Methods](#library-methods)
    * [Constructor: Exosite(<em>mode, settings</em>)](#constructor-exositemode-settings)
    * [provision(<em>callback</em>)](#provisioncallback)
    * [writeData(<em>data, token</em>)](#writedatadata-token)
    * [pollConfigIO(<em>token</em>)](#pollconfigiotoken)
    * [writeConfigIO(<em>config_io, token</em>)](#writeconfigioconfig_io-token)
    * [readAttribute(<em>attribute, callback, token</em>)](#readattributeattribute-callback-token)
    * [setDebugMode(<em>value</em>)](#setdebugmodevalue)
    * [setConfigIORefreshTimeout(<em>timeout</em>)](#setconfigiorefreshtimeouttimeout)
* [Configuring Channels In ExoSense](#configuring-channels-in-exosense)
* [Modes](#modes)
    * [MuranoProduct](#muranoproduct)
    * [IOT_CONNECTOR](#iotconnector)
* [Troubleshooting](#troubleshooting)
    * [Authorization Issues](#authorization-issues)

## What This Library Does ##

- Provides an API wrapper to create/provision a device.
- Provides an API wrapper for the `data_in` signal.
- Provision device (via token auth).
- Write data.
- Acknowledge `config_io` write.

## Pre-requisites ##

- An Electric Imp account: [sign up here](https://impcentral.electricimp.com/login).
- An Exosite Murano account: [sign up here](https://info.exosite.com/platform-sign-up).
- An Exosite Murano product which has WebServices (ie. [Exchange Elements](http://docs.exosite.com/reference/ui/exchange/adding-exchange-elements-guide/)) enabled.
- An Exosite Murano product which has `config_io` and `data_in` defined in `resources`.

## General Library Usage ##

The main things to implement when using this library are:

- **Token Handling** A token is received when [provisioning](#provisioncallback) in a callback, or set directly in Murano. This token must persist across device restarts.
- **config_io** The `config_io` signal defines the type of data that will be transmitted to ExoSense. This can either be set from the device or from the cloud. For more information on `config_io`, please see the [ExoSense documentation on channel configuration](https://exosense.readme.io/docs/channel-configuration).
- **Writing Data** Data to be [written](#writedatadata-token) should first be formatted to match the `config_io` given to ExoSense.

For a more complete example of the library's usage, please see the [Example](./Example) directory, which contains sample agent and device code, and en example `config_io` file.

## Library Methods ##

### Constructor: Exosite(*mode, settings*) ###

| Parameter | Type | Required? | Description |
| -- | -- | -- | -- |
| *mode* | Enum | Yes | The mode in which to execute the library. The available modes [are listed below.](#modes) |
| *settings* | Table | Yes | A table of settings for the selected mode |

#### Example ####

```squirrel
const PRODUCT_ID = <MY_PRODUCT_ID>;
local settings = {};
settings.productId <- PRODUCT_ID;

exositeAgent <- Exosite(EXOSITE_MODES.MURANO_PRODUCT, settings);
```

### provision(*callback*) ###

This method provisions the device with ExoSense using the information provided in the constructor.

A successful request will contain the CIK Auth token in *response.body*. You will need this value in order to write data and perform other tasks.

#### Parameters ####

| Parameter | Type | Required? | Description |
| -- | -- | -- | -- |
| *callback* | Function | Yes | A function to be executed to handle the read request's response |

#### Returns ####

Nothing.

### writeData(*data, token*) ###

This method writes a table of data to the `data_in` signal in Murano.

For more information on `data_in` and `config_io`, please see the [ExoSense documentation on channel configuration](https://exosense.readme.io/docs/channel-configuration).

#### Parameters ####

| Parameter | Type | Required? | Description |
| -- | -- | -- | -- |
| *data* | Table | Yes | The data to be written to `data_in`. Each key should match a channel identifier in your `config_io` |
| *token* | String | Yes | The device's CIK Authorization token |

#### Returns ####

Nothing.

### pollConfigIO(*token*) ###

This method uses long polling to check for updates to the `config_io`. This should be used if the `config_io` could be set from the cloud.

#### Parameters ####

| Parameter | Type | Required? | Description |
| -- | -- | -- | -- |
| *token* | String | Yes | The device's CIK Authorization token |

#### Returns ####

Nothing.

### writeConfigIO(*config_io, token*) ###

This method writes the given `config_io` to the server. This will not need to be used directly if the `config_io` is updated from the cloud.

#### Parameters ####

| Parameter | Type | Required? | Description |
| -- | -- | -- | -- |
| *config_io* | String | Yes | The `config_io` to post formatted as `"config_io=<jsonencoded_config_io_table>"` |
| *token* | String | Yes | The device's CIK Authorization token |

#### Returns ####

Nothing.

### readAttribute(*attribute, callback, token*) ###

This method requests the value of the specified attribute.

#### Parameters ####

| Parameter | Type | Required? | Description |
| -- | -- | -- | -- |
| *attribute* | String | Yes | The attribute whose value is to be read |
| *callback* | Function | Yes | A function to be executed to handle the read request's response |
| *token* | String | Yes | The device's CIK Authorization token |

#### Returns ####

Nothing &mdash; the attribute's value is accessed via the registered callback.

### setDebugMode(*value*) ###

Debug mode enables extra logging in the impCentral™ log.

#### Parameters ####

| Parameter | Type | Required? | Description |
| -- | -- | -- | -- |
| *value* | Boolean | Yes | Set to `true` to enable extra debugging information, or `false` to silence the extra logging |

#### Returns ####

Nothing.

### setConfigIORefreshTimeout(*timeout*) ###

Changes the timeout length for a configIO long poll, defaults to 15000000 ms

#### Parameters ####

| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| *timeout* | Integer | Yes | The time in milliseconds (ms) before the long poll times out and re-requests |

#### Returns ####

Nothing.

## Configuring Channels In ExoSense ##
To configure the channels in ExoSense to read correctly from the device. The key that the device uses for the data needs to be defined.

To achieve this, the user must have a `Custom` **Protocol**, with `ElectricImp` as the **Application**, and `{"key":<device's corresponding key>}` as the **app_specific_config**

For example, if the device calls
```
local conditions = {};
conditions.temp <- reading.temperature;
agent.send("reading.sent", conditions);
```

A corresponding channel configuration could look like the following:

![](media/ChannelConfigurationExample.png)


## Modes ##

This library supports the following usage modes.

### MuranoProduct ###

The `EXOSITE_MODES.MURANO_PRODUCT` mode should be selected when a user has their own Murano Product to add their device to.

#### Settings ####

| Key | Type | Required? | Description |
| -- | -- | -- | -- |
| *productId* | String | Yes | The Murano Product ID to connect and send data to |
| *deviceId*  | String | No  | The Device ID to provision as. If not provided, the Electric Imp agent ID will be used. This must be unique between devices in the product |

#### Example Settings ####

```squirrel
local settings = {};
settings.productId = "c449gfcd11ky00002";
settings.deviceId  = "device0001";
```

### IoT Connector ###

The `Exosite_modes.IOT_CONNECTOR` mode should be selected when connecting to ExoSense using the [ElectricImp IoT Connector Service](https://www.exosite.io/business//exchange/catalog/component/5d88eb136dc761ccebf20079)

#### Settings ####

| Key | Type | Required? | Description |
| -- | -- | -- | -- |
| N/A| N/A | N/A | Currently no settings are required when using the IoT Connector Mode |


## Troubleshooting ##

To assist in troubleshooting, please ensure that [Debug Mode](#setdebugmodevalue) is enabled. The debug log will viewable be in impCentral.

### Authorization Issues ###

If you are receiving 401 Unauthorized error responses, the auth token may be out of sync with the Exosite Product. To deal with this issue, clear the saved token in the agent, clear the credentials in the Murano device, and re-provision the device.

## License ##

This library is licensed under the terms of the [MIT License](./LICENSE.txt) and is copyright (c) 2019 Exosite.
