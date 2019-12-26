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

//example.agent.nut
// This example code recieves a data table from the device and posts to ExoSense on the "data_in" channel

#require "Exosite.agent.lib.nut:1.1.0"

const PRODUCT_ID = "<my_product_id>";
local _token = null;

function provision_callback(response) {
    if (response.statuscode == 200) {
        _token = response.body;

        local settings = server.load();
        settings.exosite_token <- _token;
        local result = server.save(settings);
        if (result != 0) server.error("Could not save settings!");
    } else if (response.statuscode == 409) {
        server.log("Response error, may be trying to provision an already provisioned device");
    } else {
        server.log("Token not recieved. Error: " + response.statuscode);
    }

    exositeAgent.pollConfigIO(_token);
}

function onDataRecieved(data) {
    if (_token != null) exositeAgent.writeData(data, _token);
}

local settings = {};
settings.productId <- PRODUCT_ID;;

exositeAgent <- Exosite(EXOSITE_MODES.MURANO_PRODUCT, settings);
//Enable debugMode that was defaulted to false
exositeAgent.setDebugMode(true);;

//See if we think we need to provision (no token saved)
local settings = server.load();
if ("exosite_token" in settings) {
    _token = settings.exosite_token;
    exositeAgent.pollConfigIO(_token);
} else {
    exositeAgent.provision(provision_callback.bindenv(this));
}

device.on("reading.sent", onDataRecieved.bindenv(this));
