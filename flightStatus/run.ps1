
Set-AuthenticationHeader -flightaware_user $env:flightaware_user -flightaware_api $env:flightaware_api

$flightnumber = ($req_query_flightnumber).ToUpper()

$decoded_response_url = ([System.Web.HttpUtility]::UrlDecode($req_query_callback)).TrimEnd('"')

$today = ([Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))).ToString()
$tomorrow = [Math]::Floor([decimal](Get-Date((Get-Date).AddDays(1)).ToUniversalTime()-uformat "%s"))

# Get the IATA Code from the request query param $flightnumber
$airline_iata = $flightnumber.Substring(0,2)
# Convert the IATA code to the ICAO code and pick the actual code, hence Substring
$airline_icao = Get-ICAOCode -iata $airline_iata

$flightno = $flightnumber.Substring(2)
$flightno

$flight = Get-FlightInfo -today $today -tomorrow $tomorrow -airline_icao $airline_icao -flightno $flightno -Verbose

if (($flight.error) -or (($flight.AirlineFlightSchedulesResult.data).Count -eq 0)) {
  $response_body = @{
      text = 'This flight number does not exist or does not exist in the Flightaware database for the next 24hrs.'
    }
    Send-SlackResponse -decoded_response_url $decoded_response_url -response_body $response_body
}
else {

$actualflight = ($flight.AirlineFlightSchedulesResult.data | Where-Object -FilterScript {$PSItem.ident -eq "$airline_icao$flightno"})

# output flights
$actualflight

# if multiple flights, loop through them
foreach ($iactualflight in $actualflight){
  $flightident = "${airline_icao}${flightno}@$($iactualflight.departuretime)"
  $flightInfoEx = (Get-FlightInfoEx -flightident $flightident -Headers $Headers).FlightInfoExResult.flights

  $origin = (Get-AirportInfo -airportcode $iactualflight.origin).AirportInfoResult.name
  $destination = (Get-AirportInfo -airportcode $iactualflight.destination).AirportInfoResult.name

  $airlineflightInfo = (Get-AirlineFlightInfo -faFlightID $flightInfoEx.faFlightID).AirlineFlightInfoResult

  $fdt = ConvertFrom-Unixdate $flightInfoEx.filed_departuretime
  $etd = Get-ETD -filed_ete $flightInfoEx.filed_ete -eta (ConvertFrom-Unixdate $flightInfoEx.estimatedarrivaltime)

  $delay = $etd - $fdt

  if (-not ($req_query_simple)) {
    $result = @"
    * ${req_query_user}, here is your flight info for Flight # $flightnumber / $(${iactualflight}.ident)*
    Code Share Flight # = $(if ($(${iactualflight}.actual_ident)) {$(${iactualflight}.actual_ident)} else {'n/a'})
    From = *$(${origin}) // $(${iactualflight}.origin) *
    To = *$(${destination}) // $(${iactualflight}.destination)*
    Type of aircraft = $(${iactualflight}.aircrafttype)
    Filed Departure Time = *$(Convert-Datetime (Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${flightInfoEx}.filed_departuretime)).ToString())).ToString())*
    Estimated Arrival Time = $(Convert-Datetime (Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${flightInfoEx}.estimatedarrivaltime)).ToString())).ToString())
    Current estimated time of departure = $(Get-LocalTime "$etd")
    Current Delay = $delay
    Departure Terminal = $(${airlineflightInfo}.terminal_orig)
    Departure Gate = $(${airlineflightInfo}.gate_orig)
"@
  }
  else {

    $icao_origin = $(${iactualflight}.origin)
    $icao_destination = ${iactualflight}.destination
    $airport_code_origin = (Convert-ICAOtoIATA -icao $icao_origin).iata
    $airport_code_destination = (Convert-ICAOtoIATA -icao $icao_destination).iata
      $result = @"
    * ${req_query_user}, here is your flight info for Flight # $flightnumber / $(${iactualflight}.ident)*
    From *$(${origin}) // $(${airport_code_origin})* to *$(${destination}) // $(${airport_code_destination})* on $(${iactualflight}.aircrafttype)
    Filed Departure Time = *$(Convert-Datetime (Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${flightInfoEx}.filed_departuretime)).ToString())).ToString())*
    Estimated Arrival Time = $(Convert-Datetime (Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${flightInfoEx}.estimatedarrivaltime)).ToString())).ToString())
    Current estimated time of departure = $(Get-LocalTime "$etd")
    Current Delay = $delay
    Departure terminal $(${airlineflightInfo}.terminal_orig) from gate $(${airlineflightInfo}.gate_orig)
"@
  }

  $response_body = @{
    text = "$result"
    response_type = 'ephemeral'
  }
  
  Send-SlackResponse -decoded_response_url $decoded_response_url -response_body $response_body}
}
Out-File -Encoding Ascii $response -inputObject "$(ConvertTo-Json $response_body)"