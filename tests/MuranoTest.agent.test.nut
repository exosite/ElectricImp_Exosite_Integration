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

//*****************************************************************
//   TO RUN THIS TEST
//*****************************************************************
// 1.) Change PRODUCT_ID to the product id of the testing area in Murano
// 2.) Ensure the current device being tested is not provisioned
// 3.) From the repository root run `impt test run` (see tests/README.md for more detail)

const PRODUCT_ID = "";

class MuranoTestCase extends ImpTestCase {

    _exositeAgent = null;
    _test_token = null;
    // False skips tests that have outside dependencies
    // If True ensure the device is not provisioned in the PRODUCT_ID specified
    _actually_test = false;

    default_test_settings = {};

    function setUp() {
        default_test_settings.productId <- "c449gfcd11ky00000";

        if (!_actually_test) return;
        _exositeAgent = Exosite(EXOSITE_MODES.MURANO_PRODUCT, default_test_settings);

        //Enable debugMode that was defaulted to false
        _exositeAgent.setDebugMode(true);
    }

    function test01_createDevice() {
        if (!_actually_test) return;
        return provision_test();
    }

    function test02_autoDeviceID() {
        if (!_actually_test) return;
        local inputString = "https://agent.electricimp.com/fyofyVhlsf7C";
        local expectedString =  "fyofyVhlsf7C";

        local actualString = _exositeAgent._getDeviceFromURL(inputString);
        this.assertEqual(expectedString, actualString);
    }

    function test03_writeData(){
        if (!_actually_test) return;
        return writeDataTest(_test_token);
    }

    function test04_tableGet(){
       local agent = Exosite(EXOSITE_MODES.MURANO_PRODUCT, default_test_settings); 

       local table = {};
       table.deviceId <- "one";
       table["thisKey"] <- "two";
       table.nullVal <- null;

        this.assertEqual("one", agent._tableGet(table, "deviceId"));
        this.assertEqual("two", agent._tableGet(table, "thisKey"));
        this.assertEqual(null,  agent._tableGet(table, "nullVal"));
        this.assertEqual(null,  agent._tableGet(table, "notThere"));
    }

    function test05_setDeviceId(){
       local settings = clone(default_test_settings);
       settings.deviceId <- "device1";
       local agent = Exosite(EXOSITE_MODES.MURANO_PRODUCT, settings); 

       this.assertEqual(agent._deviceId, "device1");
    }

    function test06_defaultDeviceId(){
       local agent = Exosite(EXOSITE_MODES.MURANO_PRODUCT, default_test_settings); 

       this.assertEqual(agent._deviceId, agent._getDeviceFromURL(http.agenturl()));
    }

    function test07_testCreateChannelConverterTable(){
       local agent = Exosite(EXOSITE_MODES.MURANO_PRODUCT, default_test_settings); 

       local config_io = "{\"channels\": { \"000\":{}, \"001\": { \"display_name\": \"Temp_F\", \"protocol_config\": { \"app_specific_config\": { \"key\": \"myGreatKey\" }, \"application\": \"ElectricImp\" }}}}"; 
       local expected_table = {"myGreatKey":"001"};
       local returned_table = agent._create_channel_converter_table(config_io);

        //JSON Encode since assertEqual is checking reference for the tables
        this.assertEqual(http.jsonencode(returned_table), http.jsonencode(expected_table))
    }

    function test08_testDataInTransform(){
       local agent = Exosite(EXOSITE_MODES.MURANO_PRODUCT, default_test_settings); 
       //(As proven from test07)
       local id_conversion_table = {"myGreatKey":"001"};
       
       local data_in_table = {"myGreatKey" : 42, "keyNotInConfigIO": 77}
       local expected_table = {"001" : 42, "keyNotInConfigIO": 77}

       local converted_table = agent._match_with_config_io(data_in_table, id_conversion_table);

        //JSON Encode since assertEqual is checking reference for the tables
       this.assertEqual(http.jsonencode(data_in_table), http.jsonencode(expected_table));
    }

    function provision_test() {
        return Promise(function(resolve, reject) {
            _exositeAgent.provision(function(response){
                    this.info(response.statuscode);
                    this.info(response.body);
                    if (response.statuscode == 200 || response.statuscode == 204) {
                        _test_token = response.body;
                        resolve(response.statuscode);
                    } else {
                        reject(response.statuscode);
                    }
            }.bindenv(this));
        }.bindenv(this));
    }

    function writeDataTest(_test_token){
        return Promise(function(resolve, reject) {
            local test_data = {};
            test_data.temp <- 1;
            test_data.press <- 2;
            //Write the data
            _exositeAgent._writeData_w_cb(test_data, function(response){
                //Read the data back
                readAttribute("data_in", function(response){
                    //Check it's the same
                    local expected_result = "data_in=%7b+%22press%22%3a+2%2c+%22temp%22%3a+1+%7d"
                    if (response.statuscode != 200) {
                        reject(response.statuscode);
                    } else if (response.body != expected_result) {
                        reject(response.body);
                    } else {
                        resolve(response.body);
                    }
                }.bindenv(this), _test_token);
            }.bindenv(this), _test_token);
        }.bindenv(this));
    }
}
