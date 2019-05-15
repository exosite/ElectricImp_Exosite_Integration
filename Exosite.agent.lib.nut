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

//#require "Promise.lib.nut:4.0.0"

class Exosite {
      static VERSION = "1.0.0";

     _baseURL              = null;
     _headers              = {};
     _token                = null;
     // constructor
     // Returns: null
     // Parameters:
     //      appId (reqired) : string - Exosite product ID
     //      apiToken (required) : string - Token for Exosite application, used to authorize
     //                                     all HTTP requests, must have device and devices
     //                                     permissions.
    constructor(productId) {
        _baseURL = format("https://%s.m2.exosite.io/", productId);
        //_baseURL = format("https://%s.apps.exosite.io/", productId);

        server.log("ARJ DEBUG: \n");
        server.log(_baseURL);
       _headers["Content-Type"] <- "application/x-www-form-urlencoded; charset=utf-8";
    }

    // provision - Create a new device for the product that was passed in to the constructor
    // Returns: null
    // Parameters:
    //      deviceID (required) : string - deviceID
    //
    function provision (deviceID) {
        // Create/Provision a new device in the product
        // POST /provision/activate
        local activate_url = format("%sprovision/activate", _baseURL);
        server.log("activate_url: " + activate_url + "\n");
        local req = http.post(activate_url, _headers, format("id=%s", deviceID));
        req.sendasync(provision_callback);
    }

    function provision_callback(response) {
        local err, data;
        server.log("ARJ DEBUG: \n");
        server.log(response.statuscode + "\n");
        server.log(response.body + "\n");

        if (response.statuscode == 200) { //Success
            // Need jsondecode()?
            _token <- response.body;
            server.log("token: " + _token + "\n");
        }
    }

    function write_data (table) {
        local counter = 0;
        if (_token == null) {
            server.log("Token NULL\n");
            counter = counter + 1;
            if (counter > 20) {
                return 1;
            }
            imp.wakeup(10, write_data(table).bindenv(this));
        }

        server.log("writing data with token: " + _token + "\n");
        _headers["X-Exosite-CIK"]  <-  _token;
        local req = http.post(format("%sonep:v1/stack/alias", _baseURL), _headers, "data_in=" + http.jsonencode(table));
        req.sendasync(response_error_check);
    }

    function response_error_check(response) {
        // 200 - Ok           - Successful Request, returning requested values
        // 204 - No Content   - Successful Request, nothing will be returned
        // 4xx - Client Error - There was an error with the request by the client
        // 409 - Conflict     - (Example: Provisioning a provisioned device)
        // 401 - Unauthorized - Missing or Invalid Credentials
        // 5xx - Server Error - Unhandled server error. Contact Support

        server.log("ARJ DEBUG: \n");
        //server.log(http.jsonencode(response));
        server.log(response.statuscode + "\n");
        server.log(response.body + "\n");

        return 1;
    }
}
