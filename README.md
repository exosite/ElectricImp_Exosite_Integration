# Exosite
This library provides integration with [Exosite](https://exosite.com/iot-solutions/condition-monitoring/) by wrapping the [Exosite HTTPS Device API](http://docs.exosite.com/reference/products/device-api/http/).

**To use this library, add** `#require "Exosite.agent.lib.nut:1.0.0"` **to the top of your agent code.**
  * [What this does](#what-this-does)
  * [General Usage](#general-usage)
  * [Available Functions](#available-functions)
     * [Constructor Exosite(<em>mode, settings</em>)](#constructor-exositemode-settings)
     * [provision(<em>callback</em>)](#provisioncallback)
     * [writeData(<em>table</em>, <em>token</em>)](#writedatatable-token)
     * [pollConfigIO(<em>token</em>)](#pollconfigiotoken)
     * [writeConfigIO(<em>config_io</em>, <em>token</em>)](#writeconfigioconfig_io-token)
     * [readAttribute(<em>attribute</em>, <em>callback</em>, <em>token</em>)](#readattributeattribute-callback-token)
     * [setDebugMode(<em>value</em>)](#setdebugmodevalue)
     * [setConfigIORefreshTimeout(<em>val_milliseconds</em>)](#setconfigiorefreshtimeoutval_milliseconds)
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

## Prerequisites
  - ElectricImp ImpCentral account [(Sign up here)](https://impcentral.electricimp.com/login)
  - Exosite Murano account [(Sign up here)](https://info.exosite.com/platform-sign-up)
  - Exosite Murano product has WebServices (Exchange Element) enabled.  [(Learn more about exchange elements here)](http://docs.exosite.com/reference/ui/exchange/adding-exchange-elements-guide/)

## General Usage
The main things to implement when using this library are: 
  - **Token Handling** A token is recieved when [provisioning](#provisioncallback) in a callback, or set directly in Murano. This must persist across device restarts.
  - **config_io** The config_io signal defines the type of data that will be transmitted to ExoSense. This can either be set from the device or from the cloud. For more information on config_io, checkout the [ExoSense Documentation on Channel Configuration](https://exosense.readme.io/docs/channel-configuration)
  - **Writing Data** [Writing data](#writedatatable-token) should be formatted to match the config_io given to ExoSense.

For a more complete example of usage, see Example/example.agent.nut and Example/example.device.nut


## Available Functions
### Constructor Exosite(*mode, settings*) ###
| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| mode | enum | yes | The mode to execute the library in. [Descriptions of modes are listed below.](#modes).
| settings | table | yes | A table of settings for the corresponding mode selected.

**Returns** \
Nothing

**Example**
```
const PRODUCT_ID = <my_product_id>;
local settings = {};
settings.productId <- PRODUCT_ID;

exositeAgent <- Exosite(EXOSITE_MODES.MURANO_PRODUCT, settings);
```

### provision(*callback*) ###
Provisions the device with ExoSense using the information provided in the constructor. \
A successful request will contain the CIK Auth token in the response.body. 

| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| callback | function | yes | The callback to handle the response of the read request. |

**Returns** \
Nothing

### writeData(*table*, *token*) ###
Writes a table of data to the data_in signal in Murano

| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| table | table object | yes | Table to be written to data\_in. Each key should match a channel identifier in the config\_io |
| token | string | yes | CIK Authorization token for the device | 

For more information on data_in and config_io, checkout the [ExoSense Documentation on Channel Configuration](https://exosense.readme.io/docs/channel-configuration)

### pollConfigIO(*token*) ###
Uses long polling to check for updates to the config_io. This should be used if the config_io could be set from the cloud.

| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| token | string | yes | CIK Authorization token for the device | 

### writeConfigIO(*config_io*, *token*) ###
Writes the given config_io to the server. This will not need to be used directly if the config_io is updated from the cloud.

| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| config_io | string | yes | The config_io to post formatted as "config_io=<jsonencoded_config_io_table>" | 
| token | string | yes | CIK Authorization token for the device | 

### readAttribute(*attribute*, *callback*, *token*) ###
Writes the given config_io to the server. This will not need to be used directly if the config_io is updated from the cloud.

| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| attribute | string | yes | The attribute to request a read of |
| callback | function | yes | The callback to handle the response of the read request | 
| token | string | yes | CIK Authorization token for the device | 

### setDebugMode(*value*) ###
Debug Mode enables extra logging in the server log.
| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| value | boolean | yes | True = Enable extra debugging logs | 

### setConfigIORefreshTimeout(*val_milliseconds*) ###
Changes the timeout length for a configIO long poll, defaults to 15000000 ms

| Parameter | Type | Required | Description |
| -- | -- | -- | -- |
| val_milliseconds | integer | yes | Number of milliseconds before the long poll times out and re-requests | 

## Modes ##
There are different modes that can be used with this library. Supported/Released modes are described below.
### MuranoProduct ###
**Usage** \
The `EXOSITE_MODES.MURANO_PRODUCT` mode should be selected when a user has their own Murano Product to add their device to.

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
To assist in troubleshooting, ensure [Debug Mode](#setdebugmodevalue) is enabled on the agent. The debug log will viewable be in impCentral.

### Authorization Issues ###
If you are recieving 401 Unauthorized error responses. The Auth token may be out of sync with the Exosite Product.

**Solution**

To mitigate this issue, clear the saved token in the agent, and clear credentials in the Murano device. Then, reprovision the device.

