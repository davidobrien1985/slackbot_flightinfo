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
    - example `/entry?icao=eddk` or `/entry?icao=MEL` 
  - if provided parameter is an IATA (3 letter airport code) it can call out to `/get_ICAO_from_IATA` to translate it to an ICAO code
- uses 3rd party API `http://avwx-api.azurewebsites.net/api/metar`
  - code can be found here <https://github.com/flyinactor91/AVWX-API>

# flightStatus
Function using FlightAware's (FA) commercial API to query a given flight's status, written in PowerShell.

- accepts a JSON body to its API endpoint in the following format
- uses `/FlightInfoEx` function to query the FA API for the internal FA flightID and general information about a flight
- uses `/faFlightID` function to query the FA API for Airline specific information about the flight
- responds to Slack message via delayed response

# faFlightID
Function using FlightAware's (FA) commercial API to query the internal flightID and general information for a flight

- accepts parameter 