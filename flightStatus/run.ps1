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

$airline = $flightnumber.Substring(0,3)
$flightno = $flightnumber.Substring(3)

$flight = Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirlineFlightSchedules?startDate=$($today)&endDate=$($tomorrow)&airline=$($airline)&flightno=$($flightno)" -Headers $Headers -Verbose

if ($flight.error) {
  $response_body = @{
      text = 'This flight number does not exist or does not exist in the Flightaware database.'
    }
}
else {
$actualflight = ($flight.AirlineFlightSchedulesResult.data | Where-Object -FilterScript {$PSItem.ident -eq "$flightnumber"})

$flightident = "$flightnumber@$($actualflight.departuretime)"
$flightInfoEx = (Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/FlightInfoEx?ident=$($flightident)&howMany=2" -Headers $Headers -Verbose).FlightInfoExResult.flights

$origin = (Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirportInfo?airportCode=$($actualflight.origin)" -Headers $Headers -Verbose).AirportInfoResult.name
$destination = (Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirportInfo?airportCode=$($actualflight.destination)" -Headers $Headers -Verbose).AirportInfoResult.name

$airlineflightInfo = (Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirlineFlightInfo?faFlightID=$($flightInfoEx.faFlightID)" -Headers $Headers -Verbose).AirlineFlightInfoResult

$result = @"
Flight # = *$(${actualflight}.ident)*
Code Share Flight # = $(if ($(${actualflight}.actual_ident)) {$(${actualflight}.actual_ident)} else {'n/a'})
From = *$(${origin}) // $(${actualflight}.origin) *
To = *$(${destination}) // $(${actualflight}.destination)*
Type of aircraft = $(${actualflight}.aircrafttype)
Filed Departure Time = *$((Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${actualflight}.departuretime)).ToString())).ToString())*
Estimated Arrival Time = $((Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${actualflight}.arrivaltime)).ToString())).ToString())
Departure Terminal = $(${airlineflightInfo}.terminal_orig)
Departure Gate = $(${airlineflightInfo}.gate_orig)
"@

$response_body = @{
  text = "$result"
  response_type = 'in_channel'
}
}

Invoke-RestMethod -Uri $decoded_response_url -Method Post -ContentType 'application/json' -Body (ConvertTo-Json $response_body) -Verbose

Out-File -Encoding Ascii $response -inputObject "$(ConvertTo-Json $response_body)"