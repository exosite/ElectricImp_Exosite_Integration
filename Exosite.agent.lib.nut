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
      static PDAAS_PRODUCT_ID = "c5nmke836k280000";
      static VERSION = "1.0.0";

     //Public settings variables
     //set to true to log debug message on the ElectricImp server
     debugMode             = false;
     //Number of milliseconds to timeout between config_io refreshes. 
     configIORefreshTime   = 1500000; 

     //Private variables
     _baseURL              = null;
     _headers              = {};
     _deviceId             = null;
     _configIO             = null;
     _token                = null;
     _productId            = null;
     _mode                 = null;

     // constructor
     // Returns: Nothing
     // Parameters:
     //      productId (reqired) : string - The ExoSense productId to send to
     //      deviceId (required) : string - The name of the device, needs to be unique for each device within a product
     //
    constructor(mode, settings) {
        if (!isValidMode(mode)) {
            server.error(format("Exosite Library Mode: %s not supported", mode));
        }

        _mode = mode;
        _productId = getProductId(mode, settings);

        _baseURL = format("https://%s.m2.exosite.io/", _productId);
        _deviceId = (tableGet(settings, "deviceId") == null) ?  getDeviceFromURL(http.agenturl()) : settings.deviceId;

        _headers["Content-Type"] <- "application/x-www-form-urlencoded; charset=utf-8";
        _headers["Accept"] <- "application/x-www-form-urlencoded; charset=utf-8";

        // Probably only overriding this in unit tests, otherwise we want to make sure config_io is up to date
        local overridePollConfigIO = tableGet(settings, "dontPollConfigIO");
        if (!overridePollConfigIO) {
            pollConfigIO();
        }
    }

    //Private function that makes checking a table entry easier
    // Returns: value if it exists
    //          null if it doesn't exist (or is null)
    // Parameters 
    //           table: table - table to check
    //           index: string - index to check
    function tableGet(table, index) {
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
    function getProductId(mode, settings) {
        local productId = null
        if (mode == "MuranoProduct") {
            productId = tableGet(settings, "productId");
            if (productId == null) {
                server.error("Mode MuranoProduct requires a productId in settings");
            }
        } else if (mode == "PDaaSProduct") {
            productId = PDAAS_PRODUCT_ID;
        } else {
            server.error("No product ID found");
        }

        return productId;
    }

    // Private function to check if the given mode is known/supported
    // returns boolean - True if mode found
    // Parameter:
    //           mode: string - mode identifier
    function isValidMode(mode) {
        if (mode == "MuranoProduct"
             || mode == "PDaaSProduct") {
            return true;
        }
        return false;
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
    // Returns: Nothing
    // Parameters:
    //           logVal: string - The value to log to server if debugMode flag is set.
    function debug(logVal) {
        if (debugMode) {
            server.log(logVal);
        }
    }

    // provision - Create a new device for the product that was passed in to the constructor
    // Returns: Nothing
    // Parameters: None
    //
    function provision() {
        provision_w_cb(setTokenAndGetClaimCode.bindenv(this));
    }

    // Private Function - provisions a device with a custom callback
    // this is here to assist in testing, otherwise we would just have the provision() function
    function provision_w_cb(callBack){
        if (tokenValid()) {
           server.log("Attempting to provision when there is already a token, aborting provision");
           getClaimCode();
           return;
        }
        debug("Provisioning");
        debug("headers: " + http.jsonencode(_headers));
        local activate_url = format("%sprovision/activate", _baseURL);
        local data = format("id=%s", _deviceId);
        local req = http.post(activate_url, _headers, data);
        req.sendasync(callBack);
    }

    function setTokenAndGetClaimCode(response){
        setToken(response);
        getClaimCode();
    }

    //Private Function
    // setToken - Takes the response from a provision request and sets the token locally
    //            Saves the token to non-volatile memory in "exosite_token"
    // Returns: Nothing
    // Parameters:
    //           response: object - http response object from provision request
    //
    function setToken(response) {
        debug(response.body);
        if (response.statuscode == 200) {
            debug("Setting TOKEN: " + response.body);
            _token = response.body;
            _headers["X-Exosite-CIK"]  <-  _token;

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
    // Returns: Nothing
    // Parameters: 
    //      table (required) : string - The table to be written to "data_in".
    //                                 This table should conform to the config_io for the device.
    //                                 That is, each key should match a channel identifier and the value type should match the channel's data type.
    //
    // This is anticipated to be the function to call for device.on("reading.sent", <pointer_to_this_function>);
    function writeData(table) {
        writeData_w_cb(table, responseErrorCheck.bindenv(this));
    }

    //Private Function
    // this is here to assist in testing, otherwise we would just have the writeData() function
    // Returns: Nothing
    // Parameters: 
    //      table (required) : string - The table to be written to "data_in".
    //                                 This table should conform to the config_io for the device.
    //                                 That is, each key should match a channel identifier and the value type should match the channel's data type.
    //      callBack (required) : function - callBack function for the http write request
    function writeData_w_cb(table, callBack){
        if (!tokenValid()) return;

        debug("writeData: " + http.jsonencode(table));
        debug("headers: " + http.jsonencode(_headers));

        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), _headers, "data_in=" + http.jsonencode(table));
        req.sendasync(callBack.bindenv(this));
    }

    // pollConfigIO - Fetches the config_io from the Exosite server and writes it back. This is how the device acknowledges the config_io
    // Returns: Nothing
    // Parameters: None
    function pollConfigIO() {
        if (!tokenValid()) {
            imp.wakeup(configIORefreshTime, pollConfigIO.bindenv(this));
            return;
        }

        local configIOHeaders = clone(_headers);
        if (_configIO != null) {
            //Long Poll for a change if we already have one. Else, just grab it
            configIOHeaders["Request-Timeout"] <- configIORefreshTime;
        }
        configIOHeaders["X-Exosite-CIK"]  <-  _token;

        debug("fetching config_io");
        debug("headers: " + http.jsonencode(configIOHeaders));

        local req = http.get(format("%sonep:v1/stack/alias?config_io", _baseURL), configIOHeaders);
        req.sendasync(pollConfigIOCallback.bindenv(this));
    }

    // pollConfigIOCallback - Callback for the pollConfigIO request
    // Returns: null
    // Parameters:
    //             response - the response object for the http request
    //
    // This is split from having writeConfigIO be the callback directly so that a user can write their own string via writeConfigIO.
    function pollConfigIOCallback(response) {
        debug("Server Response: \n");
        debug(response.statuscode + "\n");
        debug(response.body + "\n");
        if (response.statuscode == 200){
            writeConfigIO(response.body);
        } else if (response.statuscode == 204) {
            _configIO = "";
        }else if (response.statuscode == 304) {
            debug("config_io not modified, not writing back");
        } else {
            server.log ("Error in pollConfigIOCallback, ResponseCode: " + response.statuscode + response.body);
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

    // writeConfigIO - Writes a config via http post request
    // Returns: null
    // Parameters:
    //            config_io : string - the config_io to post formatted as "config_io=<config_io_value>"
    //
    // The config_io is the 'contract' between the device and ExoSense of how the data is going to be transmitted
    // See https://exosense.readme.io/docs/channel-configuration for more information
    function writeConfigIO(config_io){
        if (!tokenValid()) return;
        debug("writeConfigIO: " + config_io);
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

        _headers["X-Exosite-CIK"]  <-  _token;
        debug("fetching attribute: " + attribute);
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
                debug("Found stored Token: " + settings.exosite_token);
                _token = settings.exosite_token;
                _headers["X-Exosite-CIK"]  <-  _token;
            } else {
                server.log("No token found, maybe need to provision?");
                return false;
            }
        }
        return true;
    }

    // getClaimCode - Get's the claim code of the device for the user to claim in PDaaS
    //                 Note, the device must be provisioned.
    //
    //  Returns: string - Claim code
    function getClaimCode() {
        // This is only valid in Product as a Service
        if (mode != "PDaaSProduct") return;

        server.log("Requesting Claim code for: " + _deviceId);
        local url = format("https://%s.apps.exosite.io/api/devices/%s/reset", PDAAS_PRODUCT_ID, _deviceId);
        local req = http.get(url, _headers);
        req.sendasync(getClaimCode_Callback.bindenv(this));
    }

    function getClaimCode_Callback(response){
        if (response.statuscode == 200) {
            server.log("Claim Code: " + response.body);
        } else {
            server.log(format("Error: Did not receive a claim code, Response Code: %d - Body:%s", response.statuscode, response.body));
        }
    }
}

//*********************************************************
// Local Run of Agent Code
// Uncommnent the following code to test the agent locally (not released to electricImp)
// Limitations of ElectricImp require this all to be in the same file.
//*********************************************************
//BEGIN LOCAL AGENT CODE
    const PRODUCT_ID = "c449gfcd11ky00000";

    local settings = {};
    settings.productId <- PRODUCT_ID;

//    exositeAgent <- Exosite("MuranoProduct", settings);
    exositeAgent <- Exosite("PDaaSProduct", settings);
    exositeAgent.provision();

    //Enable debugMode that was defaulted to false
    exositeAgent.debugMode = true;

    device.on("reading.sent", exositeAgent.writeData.bindenv(exositeAgent));
//END LOCAL AGENT CODE

//*********************************************************
// Testing workaround
// Uncomment the following block of code for tests to pass
// Must be commented for relase
//************************************************************
//BEGIN TEST WORKAROUND
    function noop(data) {
        //Do nothing
    }

//    device.on("reading.sent", noop);
//END TEST WORKAROUND
