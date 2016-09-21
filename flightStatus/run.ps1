Function ConvertFrom-Unixdate ($UnixDate) {
  [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
}

# http://blog.tyang.org/2012/01/11/powershell-script-convert-to-local-time-from-utc/
Function Get-LocalTime($UTCTime)
{
$strCurrentTimeZone = 'AUS Eastern Standard Time'
$TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)
$LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
Return $LocalTime
}

Function Convert-Datetime {
  param (
  $dateTimeobject
  )

  $newDateTime = Get-Date $datetimeobject -Format 'dd/MM/yyyy hh:mm:ss'
  $newDateTime
}

$pair = "$($env:flightaware_user):$($env:flightaware_api)"
$encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
  Authorization = $basicAuthValue
}

$decoded_response_url = ([System.Web.HttpUtility]::UrlDecode($req_query_callback)).TrimEnd('"')

$today = ([Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))).ToString()
$tomorrow = [Math]::Floor([decimal](Get-Date((Get-Date).AddDays(1)).ToUniversalTime()-uformat "%s"))

$flightnumber = ($req_query_flightnumber).ToUpper()


# Get the IATA Code from the request query param $flightnumber
$airline_iata = $flightnumber.Substring(0,2)
# Convert the IATA code to the ICAO code and pick the actual code, hence Substring
$airline_icao = (Invoke-RestMethod -Method Get -Uri https://dogithub.azurewebsites.net/api/convert_airline_IATA_to_ICAO?iata=${airline_iata}).SubString(0,3)
$airline_icao
$flightno = $flightnumber.Substring(2)
$flightno

$flight = Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirlineFlightSchedules?startDate=$($today)&endDate=$($tomorrow)&airline=$($airline_icao)&flightno=$($flightno)" -Headers $Headers -Verbose

if ($flight.error) {
  $response_body = @{
      text = 'This flight number does not exist or does not exist in the Flightaware database.'
    }
}
else {

$actualflight = ($flight.AirlineFlightSchedulesResult.data | Where-Object -FilterScript {$PSItem.ident -eq "$airline_icao$flightno"})

# output flights
$actualflight

# if multiple flights, loop through them
foreach ($iactualflight in $actualflight){
  $flightident = "${airline_icao}${flightno}@$($iactualflight.departuretime)"
  $flightInfoEx = (Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/FlightInfoEx?ident=$($flightident)&howMany=2" -Headers $Headers -Verbose).FlightInfoExResult.flights

  $origin = (Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirportInfo?airportCode=$($iactualflight.origin)" -Headers $Headers -Verbose).AirportInfoResult.name
  $destination = (Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirportInfo?airportCode=$($iactualflight.destination)" -Headers $Headers -Verbose).AirportInfoResult.name

  $airlineflightInfo = (Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirlineFlightInfo?faFlightID=$($flightInfoEx.faFlightID)" -Headers $Headers -Verbose).AirlineFlightInfoResult

  if (-not ($req_query_simple)) {
    $result = @"
    * ${req_query_user}, here is your flight info for Flight # $flightnumber / $(${iactualflight}.ident)*
    Code Share Flight # = $(if ($(${iactualflight}.actual_ident)) {$(${iactualflight}.actual_ident)} else {'n/a'})
    From = *$(${origin}) // $(${iactualflight}.origin) *
    To = *$(${destination}) // $(${iactualflight}.destination)*
    Type of aircraft = $(${iactualflight}.aircrafttype)
    Filed Departure Time = *$(Convert-Datetime (Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${iactualflight}.departuretime)).ToString())).ToString())*
    Estimated Arrival Time = $(Convert-Datetime (Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${iactualflight}.arrivaltime)).ToString())).ToString())
    Departure Terminal = $(${airlineflightInfo}.terminal_orig)
    Departure Gate = $(${airlineflightInfo}.gate_orig)
"@
  }
  else {

    $icao_origin = $(${iactualflight}.origin)
    $icao_destination = ${iactualflight}.destination
    $airport_code_origin = (Invoke-RestMethod -Method Get -Uri https://dogithub.azurewebsites.net/api/get_IATA_from_ICAO?code=${icao_origin}).iata
    $airport_code_destination = (Invoke-RestMethod -Method Get -Uri https://dogithub.azurewebsites.net/api/get_IATA_from_ICAO?code=${icao_destination}).iata
      $result = @"
    * ${req_query_user}, here is your flight info for Flight # $flightnumber / $(${iactualflight}.ident)*
    From *$(${origin}) // $(${airport_code_origin})* to *$(${destination}) // $(${airport_code_destination})* on $(${iactualflight}.aircrafttype)
    Filed Departure Time = *$(Convert-Datetime (Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${iactualflight}.departuretime)).ToString())).ToString())*
    Estimated Arrival Time = $(Convert-Datetime (Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${iactualflight}.arrivaltime)).ToString())).ToString())
    Departure terminal $(${airlineflightInfo}.terminal_orig) from gate $(${airlineflightInfo}.gate_orig)
"@
  }

  $response_body = @{
    text = "$result"
    response_type = 'in_channel'
  }
  
  Invoke-RestMethod -Uri $decoded_response_url -Method Post -ContentType 'application/json' -Body (ConvertTo-Json $response_body) -Verbose
}
}
Out-File -Encoding Ascii $response -inputObject "$(ConvertTo-Json $response_body)"