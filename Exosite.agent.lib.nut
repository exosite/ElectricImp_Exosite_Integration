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

    _baseURL              = null;
    _headers              = {};
    _deviceID             =  null;
    _password             =  null;
    _config_io            = "";
    config_io_refresh_time = 60; // Change for number of seconds to wait and refresh the config_io file
    debug_mode = false;

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

        _deviceID = deviceId;
        _password = password;

        //Start polling for config_io
        fetch_config_io();
    }

    // debug - prints out to server.log if the debug flag is true
    function debug(log_val){
        if (debug_mode) {
            server.log(log_val);
        }
    }

    // provision - Create a new device for the product that was passed in to the constructor
    // Returns:
    // Parameters:
    //
    function provision () {
        return Promise(function(resolve, reject){
                local activate_url = format("%sprovision/activate", _baseURL);
                local data = format("id=%s&password=%s", _deviceID, _password);
                local req = http.post(activate_url, _headers, data);
                req.sendasync(function(response){
                        return (response.statuscode == 200 || response.statuscode == 204) ? resolve(response.body) : reject("Provisioning Failed: " + response.statuscode);
                        }.bindenv(this));
                }.bindenv(this))
    }

    // write_data - Write a table to the "data_in" channel in the Exosite product
    // Returns: null
    // Parameters: 
    //      table (reqired) : string - The table to be written to "data_in".
    //                                 This table should conform to the config_io for the device.
    //                                 That is, each key should match a channel identifier and the value type should match the channel's data type.
    //
    function write_data (table) {
        debug("write_data: " + http.jsonencode(table));
        debug("headers: " + http.jsonencode(_headers));

        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), _headers, "data_in=" + http.jsonencode(table));
        req.sendasync(response_error_check.bindenv(this));
    }

    // fetch_config_io - Fetches the config_io from the Exosite server and writes it back. This is how the device acknowledges the config_io
    // Returns: null
    // Parameters: None
    //
    function fetch_config_io() {
        debug("headers: " + http.jsonencode(_headers));
        local req = http.get(format("%sonep:v1/stack/alias?config_io", _baseURL), _headers);
        req.sendasync(fetch_config_io_cb.bindenv(this));

        imp.wakeup(config_io_refresh_time, fetch_config_io.bindenv(this));
    }

    // fetch_config_io_cb - Callback for the fetch_config_io request
    // Returns: null
    // Parameters:
    //             response - the response object for the http request
    function fetch_config_io_cb(response) {
        write_config_io(response.body);
    }

    // write_config_io - Writes a config via http post request
    // Returns: null
    // Parameters:
    //            config_io : string - the config_io to post formatted as "string=<config_io_value>"
    function write_config_io(config_io){
        debug("write_config_io: " + config_io);
        debug("headers: " + http.jsonencode(_headers));

        _config_io = config_io;
        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), _headers, _config_io);
        req.sendasync(response_error_check.bindenv(this));
    }

    // response_error_check - Checks the status code of an http response and prints to the server log
    // Returns: The response's status code
    // Parameters:
    //            - response : object - response object from the http request
    function response_error_check(response) {
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

local product_id = "c449gfcd11ky00000";
local device_id  = "feed123";
local password   = "123456789ABCDEabcdeF";

exosite_agent <- Exosite(product_id, device_id, password);
exosite_agent.provision();

exosite_agent.debug_mode = true; //Default to false
exosite_agent.config_io_refresh_time = 15; // Change for number of seconds to wait and refresh the config_io file

device.on("reading.sent", exosite_agent.write_data.bindenv(exosite_agent));

