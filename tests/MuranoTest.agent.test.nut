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
    _exositeAgent = null;

    function setUp() {
        _exositeAgent = Exosite(productId, null);
        _exositeAgent.provision();

        //Enable debugMode that was defaulted to false
        _exositeAgent.debugMode = true;
        //Change number of seconds between config_io refreshes that was defaulted to 60 seconds
        _exositeAgent.configIORefreshTime = 5;
    }

    //function test01_createDevice() {
    //    return provision_test();
    //}

    function test02_autoDeviceID() {
        local inputString = "https://agent.electricimp.com/fyofyVhlsf7C";
        local expectedString =  "fyofyVhlsf7C";

        local actualString = _exositeAgent.getDeviceFromURL(inputString);
        this.assertEqual(expectedString, actualString);
    }

    function provision_test() {
        return Promise(function(resolve, reject) {
            _exositeAgent.provision_w_cb(function(response){
                    if (response.statuscode == 200 || response.statuscode == 204) {
                        resolve(response.statuscode);
                    } else {
                        reject(response.statuscode);
                    }
            }.bindenv(this));
        }.bindenv(this));
    }
}
