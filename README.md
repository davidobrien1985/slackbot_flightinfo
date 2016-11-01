# Introduction
Purpose of this code is to provide a Slack Slash command support via Azure Functions that will query 3rd party APIs for aviation airport weather or flight status information.
This code uses the www.flightaware.com REST API, a commercial API that requires a sign in. Other APIs can be used, however this code here was written specifically for the FlightAware API.

# General requirements

The following requirements need to be met for this code to work.
- following environment variables need to be configured inside of the Azure Function app
  - flightaware_user
    - user name 
  - flightaware_api
    - FlightAware API key for above user name
- Slack Team with a Slash command configured to trigger the `entry` function 

# entry
Function that calls in to the other functions, written in NodeJS.

- supports being called from a Slack Slash command (<https://api.slack.com/slash-commands>)
- requires a JSON body as input
- in current implementation it calls out to `/metarslackbot`
- will make sure to respond to Slash command as quickly as possible to ensure it doesn't time out in Slack
  - Slack requires a response in under 3000ms or it will present a time out to the user
  - child functions are developed to use a `callback` parameter to provide a delayed response back to Slack

# metarSlackbot
Function using 3rd party weather API to output airport weather, written in PowerShell.
- supports the following parameters
  - query string parameter `icao`
    - example `/metarslackbot?icao=eddk` or `/metarslackbot?icao=MEL` 
  - if provided parameter is an IATA (3 letter airport code) it can call out to `/get_ICAO_from_IATA` to translate it to an ICAO code
- uses 3rd party API `http://avwx-api.azurewebsites.net/api/metar`
  - code can be found here <https://github.com/flyinactor91/AVWX-API>
- responds to Slack message via delayed response
- requires PSFlightAware module to exist in `/metarslackbot/modules` folder

# flightStatus
Function using FlightAware's (FA) commercial API to query a given flight's status, written in PowerShell.
This app will query the next available flight for a given flight number looking up to 24hrs ahead.

- accepts a JSON body to its API endpoint in the following format
- supports the following parameters
  - query string parameter `flightnumber`
    - example `/flightStatus?flightnumber=QF400` 
    - airline code *must* be the IATA identifier of an airline
- responds to Slack message via delayed response
- requires PSFlightAware module to exist in `/metarslackbot/modules` folder

# Installation

*Option A*
1. Fork the repository into your own git account
2. Create an Azure Function app
3. Configure Continuous Integration for the Function App and integrate it with your git repository
4. Create a Slack Slash command and configure it to trigger the `entry` function

*Option B*
1. Clone or download this repository to your computer
2. Create an Azure Function app
3. Manually copy the code to your Azure Function app
4. Create a Slack Slash command and configure it to trigger the `entry` function