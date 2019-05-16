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
    productId = "c449gfcd11ky00000";
    deviceId = "feed123";
    password = "123456789ABCDEabcdeF";
    _token = null;
    _exositeAgent = null;

    function setUp() {
        _exositeAgent = Exosite(productId, deviceId, password);
    }

    function test01_createDevice_and_writeData() {
        this.info("Starting test");
         _exositeAgent.provision().then(writeData.bindenv(this), failTest.bindenv(this));
    }

    function writeData(response){
            this.info("Writing Data");
            return Promise(function(resolve, reject){

                local dataIN = {};
                dataIN["testValue"] <- 3;
                _exositeAgent.write_data(dataIN);
            }.bindenv(this))
    }

    function failTest(rejection){
        this.info("REJECTED!!!!!!!!!1");
        this.info("Failed test: " + rejection);
    }
}
