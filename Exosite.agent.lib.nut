// MIT License

// Copyright 2018 Electric Imp

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

     // constructor
     // Returns: null
     // Parameters:
     //      appId (reqired) : string - Exosite product ID
     //      apiToken (required) : string - Token for Exosite application, used to authorize
     //                                     all HTTP requests, must have device and devices
     //                                     permissions.
    constructor(productId, deviceId, password) {
        _baseURL = format("https://%s.m2.exosite.io/", productId);

       _headers["Content-Type"] <- "application/x-www-form-urlencoded; charset=utf-8";
       _deviceID = deviceId;
       _password = password;
    }

    // provision - Create a new device for the product that was passed in to the constructor
    // Returns: 
    // Parameters:
    //      
    //
    function provision () {
        // Create/Provision a new device in the product
        // POST /provision/activate
        return Promise(function(resolve, reject){
            local activate_url = format("%sprovision/activate", _baseURL);
            local data = format("id=%s&password=%s", _deviceID, _password);
            local req = http.post(activate_url, _headers, data);
            req.sendasync(function(response){
                return (response.statuscode == 200 || response.statuscode == 204) ? resolve(response.body) : reject("Provisioning Failed: " + response.statuscode);
            }.bindenv(this));
        }.bindenv(this))
    }

    function write_data (table) {
        local counter = 0;

        local passwordHash = "Basic " + http.base64encode(_deviceID + ":" + _password);
        _headers["Authorization"]  <-  passwordHash;
        server.log(http.jsonencode(table));

        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), _headers, "data_in=" + http.jsonencode(table));
        req.sendasync(response_error_check);
    }

    function response_error_check(response) {
        // 200 - Ok           - Successful Request, returning requested values
        // 204 - No Content   - Successful Request, nothing will be returned
        // 4xx - Client Error - There was an error with the request by the client
        // 409 - Conflict     - (Example: Provisioning a provisioned device)
        // 401 - Unauthorized - Missing or Invalid Credentials
        // 415 - Unsupported media type - missing header
        // 5xx - Server Error - Unhandled server error. Contact Support

        server.log("Server Response: \n");
        //server.log(http.jsonencode(response));
        server.log(response.statuscode + "\n");
        server.log(response.body + "\n");

        return 0;
    }
}

local product_id = "c449gfcd11ky00000";
local device_id  = "feed123";
local password   = "123456789ABCDEabcdeF";

exosite_agent <- Exosite(product_id, device_id, password);
exosite_agent.provision();

device.on("reading.sent", exosite_agent.write_data.bindenv(exosite_agent));
