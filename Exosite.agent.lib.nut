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
     _headers              = null;
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
                     "Authorization" : format("Bearer %s", apiToken)};

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
        local req = http.post(format("%s/provision/activate", _baseURL), _headers, format("id=%s", deviceID));
        req.sendasync(create_device_callback(res).bindenv(this));
    }

    function create_device_callback(response) {
        local err, data;
        if (response.statuscode == 204) { //Success
            // Need jsondecode()?
            _token = response.data;
            _headers["X-Exosite-CIK"]  <-  _token;
        }
    }

    function write_data (key, value) {
        local req = http.post(format("%s/onep:v1/stack/alias", _baseURL), _headers, format("%s=%s", key, value));
        req.sendasync(res);
    }

    function write_table (dataTable) {
        if (dataTable.len() == 0) {
            return;
        }

        data_in_string = ""
        foreach (key, value in dataTable) {
            data_in_string = data_in_string + format("%s=%s&", key, value);
        }

        //Strip off the trailing '&' character
        data_in_string = data_in_string.slice(0, data_in_string.len()-1)

        local req = http.post(format("%s/onep:v1/stack/alias", _baseURL), _headers, format("%s=%s", key, value));
        req.sendasync(res);
    }

    function response_error_check(respose) {
        // 200 - Ok           - Successful Request, returning requested values
        // 204 - No Content   - Successful Request, nothing will be returned
        // 4xx - Client Error - There was an error with the request by the client
        // 401 - Unauthorized - Missing or Invalid Credentials
        // 5xx - Server Error - Unhandled server error. Contact Support

        return 1;
    }
}
