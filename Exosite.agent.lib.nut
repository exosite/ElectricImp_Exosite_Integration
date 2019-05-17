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
     debugMode             = true;
     //Number of seconds to wait between config_io refreshes. 
     configIORefreshTime   = 60; 

     //Private variables
     _baseURL              = null;
     _headers              = {};
     _deviceId             =  null;
     _configIO             =  "";
     _token                = null;

     // constructor
     // Returns: null
     // Parameters:
     //      productId (reqired) : string - The productId to send to, this is provided by Exosite/Murano/ExoSense
     //      deviceId (required) : string - The name of the device, needs to be unique for each device within a product
     //
    constructor(productId, deviceId) {
        _baseURL = format("https://%s.m2.exosite.io/", productId);
        _deviceId = (deviceId == null) ? getDeviceFromURL(http.agenturl()) : deviceId;

        _headers["Content-Type"] <- "application/x-www-form-urlencoded; charset=utf-8";
        _headers["Accept"] <- "application/x-www-form-urlencoded; charset=utf-8";

        //Start polling for config_io
        fetchConfigIO();
    }

    //Private Helper function to get unique ID from each device
    // Returns: ElectricImps AgentID (Unique per device)
    // Parameters:
    //         urlString: string - The agent's URL. This can be retrieved via http.agenturl()
    function getDeviceFromURL(urlString) {
        local splitArray = split(urlString, "/");
        local lastEntry = splitArray.top();
        return lastEntry;
    }

    // debug - prints out to server.log if the debug flag is true
    // Returns: None
    // Parameters:
    //           logVal: string - The value to log to server if debugMode flag is set.
    function debug(logVal) {
        if (debugMode) {
            server.log(logVal);
        }
    }

    // provision - Create a new device for the product that was passed in to the constructor
    // Returns: None
    // Parameters: None
    //
    function provision() {
        provision_w_cb(setToken.bindenv(this));
    }

    // Private Function - provisions a device with a custom callback
    // this is here to assist in testing, otherwise we would just have the provision() function
    function provision_w_cb(callBack){
        if (tokenValid()) {
           server.log("Attempting to provision when there is already a token, aborting provision");
           return;
        }
        debug("Provisioning");
        debug("DEBUG_MESSAGE");
        debug("headers: " + http.jsonencode(_headers));
        local activate_url = format("%sprovision/activate", _baseURL);
        local data = format("id=%s", _deviceId);
        local req = http.post(activate_url, _headers, data);
        req.sendasync(callBack);
    }

    //Private Function
    // setToken - Takes the response from a provision request and sets the token locally
    //            Saves the token to non-volatile memory in "exosite_token"
    // Returns: None
    // Parameters:
    //           response: object - http response object from provision request
    //
    function setToken(response) {
        server.log(response.body);
        if (response.statuscode == 200) {
            server.log("Setting TOKEN: " + response.body);
            _token = response.body;
            if (_token != null) _headers["X-Exosite-CIK"]  <-  _token;
            local settings = server.load();
            settings.exosite_token <- _token;
            local result = server.save(settings);
            if (result != 0) server.error("Could not save settings!");
        } else if (response.statuscode == 409) {
            server.log("Response error, may be trying to provision an already provisioned device");
        } else {
            server.log("Token not recieved. Error: " + response.statuscode);
        }
    }


    // writeData - Write a table to the "data_in" channel in the Exosite product
    // Returns: null
    // Parameters: 
    //      table (required) : string - The table to be written to "data_in".
    //                                 This table should conform to the config_io for the device.
    //                                 That is, each key should match a channel identifier and the value type should match the channel's data type.
    //
    // This is anticipated to be the function to call for device.on("reading.sent", <pointer_to_this_function>);
    function writeData(table) {
        writeData_w_cb(table, responseErrorCheck.bindenv(this));
    }

    function writeData_w_cb(table, callBack){
        if (!tokenValid()) return;

        server.log("writeData: " + http.jsonencode(table));
        debug("headers: " + http.jsonencode(_headers));

        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), _headers, "data_in=" + http.jsonencode(table));
        req.sendasync(callBack.bindenv(this));
    }

    // fetchConfigIO - Fetches the config_io from the Exosite server and writes it back. This is how the device acknowledges the config_io
    // Returns: null
    // Parameters: None
    function fetchConfigIO() {
        if (!tokenValid()) {
            imp.wakeup(configIORefreshTime, fetchConfigIO.bindenv(this));
            return;
        }

        debug("fetching config_io");
        if (_token != null) _headers["X-Exosite-CIK"]  <-  _token;
        debug("headers: " + http.jsonencode(_headers));

        local req = http.get(format("%sonep:v1/stack/alias?config_io", _baseURL), _headers);
        if (_token != null) req.sendasync(fetchConfigIOCallback.bindenv(this));

        imp.wakeup(configIORefreshTime, fetchConfigIO.bindenv(this));
    }

    // fetchConfigIOCallback - Callback for the fetchConfigIO request
    // Returns: null
    // Parameters:
    //             response - the response object for the http request
    //
    // This is split from having writeConfigIO be the callback directly so that a user can write their own string via writeConfigIO.
    function fetchConfigIOCallback(response) {
        writeConfigIO(response.body);
    }

    // writeConfigIO - Writes a config via http post request
    // Returns: null
    // Parameters:
    //            config_io : string - the config_io to post formatted as "string=<config_io_value>"
    //
    // The config_io is the 'contract' between the device and ExoSense of how the data is going to be transmitted
    // See https://exosense.readme.io/docs/channel-configuration for more information
    function writeConfigIO(config_io){
        if (!tokenValid()) return;
        server.log("writeConfigIO: " + config_io);
        debug("headers: " + http.jsonencode(_headers));

        _configIO = config_io;
        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), _headers, _configIO);
        req.sendasync(responseErrorCheck.bindenv(this));
    }

    // readAttribute - Fetches the given attribute from the Exosite server. 
    // Returns: null
    // Parameters: None
    function readAttribute(attribute, callBack) {
        if (!tokenValid()) return;

        debug("fetching attribute: " + attribute);
        _headers["X-Exosite-CIK"]  <-  _token;
        debug("headers: " + http.jsonencode(_headers));

        local req = http.get(format("%sonep:v1/stack/alias?%s", _baseURL, attribute), _headers);
        req.sendasync(callBack.bindenv(this));
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

    // Private Function
    // tokenValid - Checks for a token in the _token variable, 
    //              if it's not there, attempts to revtrieve it from non-volatile memory, 
    //              if it's still not there, returns false
    //
    //  Returns: true if _token is populated.
    //           false if no _token found.
    //
    function tokenValid(){
        if (_token == null) {
            local settings = server.load();
            if (settings.rawin("exosite_token")) {
                server.log("Found stored Token: " + settings.exosite_token);
                _token = settings.exosite_token;
                if (_token != null) _headers["X-Exosite-CIK"]  <-  _token;
            } else {
                server.log("No token found, maybe need to provision?");
                //provision();
                return false;
            }
        }
        return true;
    }

}

// Testing workaround
// Uncomment the following block of code for tests to pass
// Must be commented for relase

//BEGIN TEST WORKAROUND
function noop(data) {
    //Do nothing
}

device.on("reading.sent", noop);
//END TEST WORKAROUND
