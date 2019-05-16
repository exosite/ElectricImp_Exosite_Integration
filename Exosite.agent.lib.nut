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

class Exosite {
      static VERSION = "1.0.0";

     //Public settings variables
     //set to true to log debug message on the ElectricImp server
     debugMode             = false;
     //Number of seconds to wait between config_io refreshes. 
     configIORefreshTime   = 60; 

     //Private variables
     _baseURL              = null;
     _headers              = {};
     _deviceId             =  null;
     _password             =  null;
     _configIO             = "";

     // constructor
     // Returns: null
     // Parameters:
     //      productId (reqired) : string - The productId to send to, this is provided by Exosite/Murano/ExoSense
     //      deviceId (required) : string - The name of the device, needs to be unique for each device within a product
     //      password (required) : string - The associated password with the device to use after provisioning
     //
    constructor(productId, deviceId, password) {
        _baseURL = format("https://%s.m2.exosite.io/", productId);

        local passwordHash = "Basic " + http.base64encode(deviceId + ":" + password);
        _headers["Content-Type"] <- "application/x-www-form-urlencoded; charset=utf-8";
        _headers["Accept"] <- "application/x-www-form-urlencoded; charset=utf-8";
        _headers["Authorization"]  <-  passwordHash;

        _deviceId = deviceId;
        _password = password;

        //Start polling for config_io
        fetchConfigIO();
    }

    // debug - prints out to server.log if the debug flag is true
    function debug(logVal){
        if (debugMode) {
            server.log(logVal);
        }
    }

    // provision - Create a new device for the product that was passed in to the constructor
    // Returns:
    // Parameters:
    //
    function provision() {
        return Promise(function(resolve, reject){
                local activate_url = format("%sprovision/activate", _baseURL);
                local data = format("id=%s&password=%s", _deviceId, _password);
                local req = http.post(activate_url, _headers, data);
                req.sendasync(function(response){
                        return (response.statuscode == 200 || response.statuscode == 204) ? resolve(response.body) : reject("Provisioning Failed: " + response.statuscode);
                        }.bindenv(this));
                }.bindenv(this))
    }

    // writeData - Write a table to the "data_in" channel in the Exosite product
    // Returns: null
    // Parameters: 
    //      table (reqired) : string - The table to be written to "data_in".
    //                                 This table should conform to the config_io for the device.
    //                                 That is, each key should match a channel identifier and the value type should match the channel's data type.
    //
    function writeData(table) {
        debug("writeData: " + http.jsonencode(table));
        debug("headers: " + http.jsonencode(_headers));

        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), _headers, "data_in=" + http.jsonencode(table));
        req.sendasync(responseErrorCheck.bindenv(this));
    }

    // fetchConfigIO - Fetches the config_io from the Exosite server and writes it back. This is how the device acknowledges the config_io
    // Returns: null
    // Parameters: None
    //
    function fetchConfigIO() {
        debug("fetching config_io");
        debug("headers: " + http.jsonencode(_headers));

        local req = http.get(format("%sonep:v1/stack/alias?config_io", _baseURL), _headers);
        req.sendasync(fetchConfigIOCallback.bindenv(this));

        imp.wakeup(config_io_refresh_time, fetchConfigIO.bindenv(this));
    }

    // fetchConfigIO - Callback for the fetchConfigIO request
    // Returns: null
    // Parameters:
    //             response - the response object for the http request
    function fetchConfigIOCallback(response) {
        writeConfigIO(response.body);
    }

    // writeConfigIO - Writes a config via http post request
    // Returns: null
    // Parameters:
    //            config_io : string - the config_io to post formatted as "string=<config_io_value>"
    function writeConfigIO(config_io){
        debug("writeConfigIO: " + config_io);
        debug("headers: " + http.jsonencode(_headers));

        _configIO = config_io;
        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), _headers, _configIO);
        req.sendasync(responseErrorCheck.bindenv(this));
    }

    // responseErrorCheck - Checks the status code of an http response and prints to the server log
    // Returns: The response's status code
    // Parameters:
    //            - response : object - response object from the http request
    function responseErrorCheck(response) {
        // 200 - Ok           - Successful Request, returning requested values
        // 204 - No Content   - Successful Request, nothing will be returned
        // 4xx - Client Error - There was an error with the request by the client
        // 409 - Conflict     - (Example: Provisioning a provisioned device)
        // 401 - Unauthorized - Missing or Invalid Credentials
        // 415 - Unsupported media type - missing header
        // 5xx - Server Error - Unhandled server error. Contact Support
        debug("Server Response: \n");
        debug(response.statuscode + "\n");
        debug(response.body + "\n");

        return response.statuscode;
    }
}

//TODO: Move to own agent (out of library)
local productId = "c449gfcd11ky00000";
local deviceId  = "feed123";
local password   = "123456789ABCDEabcdeF";

exositeAgent <- Exosite(productId, deviceId, password);
exositeAgent.provision();

//Enable debugMode that was defaulted to false
exositeAgent.debugMode = true;
//Change number of seconds between config_io refreshes that was defaulted to 60 seconds
exositeAgent.configIORefreshTime = 15;

device.on("reading.sent", exositeAgent.writeData.bindenv(exositeAgent));

