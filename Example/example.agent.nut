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

#require "Exosite.agent.lib.nut:1.0.0"

const PRODUCT_ID = "<my_product_id>";

local settings = {};
settings.productId <- PRODUCT_ID;
settings.saveToken <- true;

exositeAgent <- Exosite(EXOSITE_MODES.MURANO_PRODUCT, settings);
//Enable debugMode that was defaulted to false
exositeAgent.setDebugMode(true);

device.on("reading.sent", onDataRecieved.bindenv(this));
