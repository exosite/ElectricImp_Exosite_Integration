# Exosite Usage Example #

This example shows how to collect and send data from the sensors on an [impExplorer Kit](https://store.electricimp.com/collections/featured-products/products/impexplorer-developer-kit?variant=31118866130) to Exosite. All the code and configuration files can be found in this folder. Follow the setup instructions below to get started.

## Electric Imp SetUp ##

Follow the instructions in the [Getting Started Guide](https://developer.electricimp.com/gettingstarted) to get your impExplorer Kit connected to the internet and assigned to your first Product/Device Group. 

Once you have created a device group, copy and paste the code into the impCentral IDE.

- agent code file: [example.agent.nut](example.agent.nut) 
- device code file: [example.device.nut](example.device.nut)

## Exosite Setup ##

Create Exosite Murano product. Enable WebServices (Exchange Element) [(Learn more about exchange elements here)](http://docs.exosite.com/reference/ui/exchange/adding-exchange-elements-guide/). Create and define the following resources "config_io" and "data_in" in your product.

- config_io file: [config_io.example](config_io.example)