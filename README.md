# Exosite (WORK IN PROGRESS REPOSITORY)
This library provides integration with [Exosite](https://exosite.com/) by wrapping the [Exosite HTTPS Device API](http://docs.exosite.com/reference/products/device-api/http/).

**To use this library, add** `#require "Exosite.agent.lib.nut:1.0.0"` **to the top of your agent code.**

## TODO
- [x] Code
- [ ] Unit Tests
- [ ] General QA Tests
- [ ] Add License
- [ ] Add sample code
- [ ] Code Review
- [ ] Release to ElectricImp

## What this does (Stage 1)
Provides an API wrapper to create/provision a device in Murano \
Provides an API wrapper for the data_in signal to Murano
- [x] Provision
- [x] Write Data



## What this does not do (yet)
Handle 'data_out' from Murano \
Enable configuration via 'config_io'
- [ ] Timestamp
- [ ] Read Data
- [ ] Reprovision
- [ ] List Available Content
- [ ] Get Content Info
- [ ] Download Content
- [ ] Hybrid Read Write
- [ ] Long Polling
- [ ] Record

