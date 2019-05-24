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

enum EXOSITE_MODES {
    MURANO_PRODUCT = "EXOSITE_MODE_MURANO_PRODUCT"
}

class Exosite {
      static VERSION = "1.0.0";

     //set to true to log debug message on the ElectricImp server
     _debugMode             = false;
     //Number of milliseconds to timeout between config_io refreshes. 
     _configIORefreshTimeout   = 15000000; 

     //Private variables
     _baseURL              = null;
     //Common headers for most all requests
     _headers              = {};
     _deviceId             = null;
     _configIO             = null;
     _productId            = null;

     // constructor
     // Returns: Nothing
     // Parameters:
     //      mode (reqired) : emun (EXOSITE_MODES) - The mode to run the library in, see README for more info on options.
     //      settings (required) : table - The settings corresponding to the mode being run.
     //
    constructor(mode, settings) {
        _productId = _getProductId(mode, settings);

        _baseURL = format("https://%s.m2.exosite.io/", _productId);
        _deviceId = (_tableGet(settings, "deviceId") == null) ?  _getDeviceFromURL(http.agenturl()) : settings.deviceId;

        _headers["Content-Type"] <- "application/x-www-form-urlencoded; charset=utf-8";
        _headers["Accept"] <- "application/x-www-form-urlencoded; charset=utf-8";
    }

    //Provision - send a provision HTTP request
    // Returns - Nothing (use callback)
    // Parameters -
    //           callback: function - function to call with http response. This response will contain the Auth token on success
    function provision(callback){
        _debug("Provisioning");
        _debug("headers: " + http.jsonencode(_headers));
        local activate_url = format("%sprovision/activate", _baseURL);
        local data = format("id=%s", _deviceId);
        local req = http.post(activate_url, _headers, data);
        req.sendasync(callback);
    }

    // writeData - Write a table to the "data_in" channel in the Exosite product
    // Returns: Nothing
    // Parameters: 
    //      table (required) : string - The table to be written to "data_in".
    //                                 This table should conform to the config_io for the device.
    //                                 That is, each key should match a channel identifier and the value type should match the channel's data type.
    //            token: string - CIK Authorization token for the device
    //
    // This is anticipated to be the function to call for device.on("reading.sent", <pointer_to_this_function>);
    function writeData(table, token) {
        _writeData_w_cb(table, _responseErrorCheck.bindenv(this), token);
    }

    // pollConfigIO - Fetches the config_io from the Exosite server and writes it back. This is how the device acknowledges the config_io
    // Returns: Nothing
    // Parameters:
    //            token: string - CIK Authorization token for the device
    function pollConfigIO(token) {
        local configIOHeaders = clone(_headers);
        if (_configIO != null) {
            //Long Poll for a change if we already have one. Else, just grab it
            configIOHeaders["Request-Timeout"] <- _configIORefreshTimeout;
        }
        configIOHeaders["X-Exosite-CIK"]  <-  token;

        _debug("fetching config_io");
        _debug("headers: " + http.jsonencode(configIOHeaders));

        local req = http.get(format("%sonep:v1/stack/alias?config_io", _baseURL), configIOHeaders);
        req.sendasync(_pollConfigIOCallback.bindenv(this));
    }

    // writeConfigIO - Writes a config via http post request
    // Returns: null
    // Parameters:
    //            config_io : string - the config_io to post formatted as "config_io=<config_io_value>"
    //            token: string - CIK Authorization token for the device
    //
    // The config_io is the 'contract' between the device and ExoSense of how the data is going to be transmitted
    // See https://exosense.readme.io/docs/channel-configuration for more information
    function writeConfigIO(config_io, token){
        local configIOHeaders = clone(_headers);
        configIOHeaders["X-Exosite-CIK"]  <-  token;

        server.log("writeConfigIO: " + config_io);
        _debug("headers: " + http.jsonencode(configIOHeaders));

        _configIO = config_io;
        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), configIOHeaders, _configIO);
        req.sendasync(_responseErrorCheck.bindenv(this));
    }

    // readAttribute - Fetches the given attribute from the Exosite server. 
    // Returns: None
    // Parameters: 
    //            attribute: string - name of the attribute to get
    //            callback: function - callback for the http response from the get request
    //            token: string - CIK Authorization token for the device
    function readAttribute(attribute, callback, token) {
        local readAttributeHeaders = clone(_headers);
        readAttributeHeaders["X-Exosite-CIK"]  <-  token;
        _debug("fetching attribute: " + attribute);
        _debug("headers: " + http.jsonencode(readAttributeHeaders));

        local req = http.get(format("%sonep:v1/stack/alias?%s", _baseURL, attribute), readAttributeHeaders);
        req.sendasync(callback.bindenv(this));
    }

    //setDebugMode - Turns on or off extra logging to the server, defaults to off/false
    // Returns - None
    // Parameters:
    //          value: boolean - True = enable extra logging
    function setDebugMode(value) {
        _debugMode = value;
    }

    //setConfigIORefreshTimeout - Changes the timeout length for a configIO long poll, defaults to 15000000 ms
    // Returns - None
    // Parameters:
    //           val_milliseconds: integer - number of milliseconds before timing out the config_io long poll
    function setConfigIORefreshTimeout(val_milliseconds) {
        _configIORefreshTimeout = val_milliseconds;
    }

    //=======================================================
    //       PRIVATE FUNCTIONS
    //=======================================================

    //Private function that makes checking a table entry easier
    // Returns: value if it exists
    //          null if it doesn't exist (or is null)
    // Parameters 
    //           table: table - table to check
    //           index: string - index to check
    function _tableGet(table, index) {
        if (!table.rawin(index)) {
            return null;
        }
        return table[index];
    }

    //Private function to assist in different modes
    // Returns: string - the productId to connect to
    // Parameters: 
    //             mode: string - name of the mode being used
    //             settings: table - table of settings, required if the deviceId is expected to be in the settings table
    function _getProductId(mode, settings) {
        local productId = null;

        switch (mode) {
            case EXOSITE_MODES.MURANO_PRODUCT:
                productId = _tableGet(settings, "productId");
                if (productId == null) {
                    server.error("Mode MuranoProduct requires a productId in settings");
                }
                break;
            default:
                server.error("No product ID found");
        }

        return productId;
    }

    //Private Helper function to get unique ID from each device
    // Returns: ElectricImps AgentID (Unique per device)
    // Parameters:
    //         urlString: string - The agent's URL. This can be retrieved via http.agenturl()
    function _getDeviceFromURL(urlString) {
        local splitArray = split(urlString, "/");
        local lastEntry = splitArray.top();
        return lastEntry;
    }

    // debug - prints out to server.log if the debug flag is true
    // Returns: Nothing
    // Parameters:
    //           logVal: string - The value to log to server if _debugMode flag is set.
    function _debug(logVal) {
        if (_debugMode) {
            server.log(logVal);
        }
    }

    //Private Function
    // this is here to assist in testing, otherwise we would just have the writeData() function
    // Returns: Nothing
    // Parameters: 
    //      table (required) : string - The table to be written to "data_in".
    //                                 This table should conform to the config_io for the device.
    //                                 That is, each key should match a channel identifier and the value type should match the channel's data type.
    //      callback (required) : function - callback function for the http write request
    function _writeData_w_cb(table, callback, token){
        local writeDataHeaders = clone(_headers);
        writeDataHeaders["X-Exosite-CIK"]  <-  token;
        _debug("writeData: " + http.jsonencode(table));
        _debug("headers: " + http.jsonencode(_headers));

        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), writeDataHeaders, "data_in=" + http.jsonencode(table));
        req.sendasync(callback.bindenv(this));
    }

    // pollConfigIOCallback - Callback for the pollConfigIO request
    // Returns: null
    // Parameters:
    //             response - the response object for the http request
    //
    // This is split from having writeConfigIO be the callback directly so that a user can write their own string via writeConfigIO.
    function _pollConfigIOCallback(response) {
        _debug("Server Response: \n");
        _debug(response.statuscode + "\n");
        _debug(response.body + "\n");
        if (response.statuscode == 200){
            writeConfigIO(response.body);
        } else if (response.statuscode == 204) {
            _configIO = "";
        }else if (response.statuscode == 304) {
            _debug("config_io not modified, not writing back");
        } else {
            server.log ("Error in _pollConfigIOCallback, ResponseCode: " + response.statuscode + response.body);
        }

        //Use wakeup to break up the call stack. This could possibly create a stack overflow if we just kept calling pollConfigIO directly
        //429 - too many requests...something wrong is happening and we're calling repeatedly, sleep to counteract this...but it's wrong
        //401 - Unauthorized, may be in the process of provisioning, wait a minute
        if (response.statuscode == 429 || response.statuscode == 401) {
            server.log("Error: config_io responded with code: " + response.statuscode + ". Waiting one minute and trying again");
            imp.wakeup(60, pollConfigIO.bindenv(this));
        } else {
            imp.wakeup(0.0, pollConfigIO.bindenv(this));
        }
    }

    // responseErrorCheck - Checks the status code of an http response and prints to the server log
    // Returns: The response's status code
    // Parameters:
    //            - response : object - response object from the http request
    function _responseErrorCheck(response) {
        // 200 - Ok           - Successful Request, returning requested values
        // 204 - No Content   - Successful Request, nothing will be returned
        // 4xx - Client Error - There was an error with the request by the client
        // 409 - Conflict     - (Example: Provisioning a provisioned device)
        // 401 - Unauthorized - Missing or Invalid Credentials
        // 415 - Unsupported media type - missing header
        // 5xx - Server Error - Unhandled server error. Contact Support
        _debug("Server Response: \n");
        _debug(response.statuscode + "\n");
        _debug(response.body + "\n");

        return response.statuscode;
    }
}

