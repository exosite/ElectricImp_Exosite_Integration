// MIT License
//
// Copyright 2019 Exosite
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

class MuranoTestCase extends ImpTestCase {
    product_id = "c449gfcd11ky00000";
    device_id = "feed123";
    password = "123456789ABCDEabcdeF";
    _token = null;
    _exosite_app = null;
    _test_result = true;

    function setUp() {
        _exosite_app = Exosite(product_id, device_id, password);
    }

    function test01_createDevice_and_writeData() {
        this.info("Starting test");
         _exosite_app.provision().then(write_data.bindenv(this), fail_test.bindenv(this));
    }

    function write_data(response){
            this.info("Writing Data");
            return Promise(function(resolve, reject){

                local data_in = {};
                data_in["testValue"] <- 3;
                _exosite_app.write_data(data_in);
            }.bindenv(this))
    }

    function test02_fetch_config_io() {
        //_exosite_app.fetch_config_io();
    }

    function fail_test(rejection){
        this.info("REJECTED!!!!!!!!!1");
        this.info("Failed test: " + rejection);
    }
}
