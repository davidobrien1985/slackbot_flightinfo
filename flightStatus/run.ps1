#$in = Get-Content $req -Raw

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

#$in.Split('&')[2].Split('=')[1]
#$in.Split('&')[6].Split('=')[1]
#$in.Split('&')[8].Split('=')[1]
$request = $req_query_flightnumber #$in.Split('&')[8].Split('=')[1]

Out-File -Encoding Ascii $response -inputObject "$request"

$pair = "$($env:flightaware_user):$($env:flightaware_api)"
$encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
  Authorization = $basicAuthValue
}

$decoded_response_url = [System.Web.HttpUtility]::UrlDecode($req_query_callback)

$flightInfoEx = Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/FlightInfoEx?ident=$($request)&howMany=2" -Headers $Headers -Verbose
if ($flightInfoEx.error) {
	$response_body = @{
			text = 'This flight number does not exist or does not exist in the Flightaware database.'
		}
}
else {
	$actualflightInfo = $flightInfoEx.FlightInfoExResult.flights[0]
	$actualflightInfo

	$flightInfo = Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirlineFlightInfo?faFlightID=$($actualflightInfo.faFlightID)" -Headers $Headers -Verbose
	$flightInfo.AirlineFlightInfoResult
	(ConvertFrom-Unixdate $actualflightInfo.filed_departuretime).toString()

	$result = @{
	  'Flight #' = $flightInfo.AirlineFlightInfoResult.ident
	  'From' = $actualflightInfo.originCity
	  'To' = $actualflightInfo.destinationCity
	  'Type of aircraft' = $actualflightInfo.aircrafttype
	  'Departure Terminal' = $flightInfo.AirlineFlightInfoResult.terminal_orig
	  'Departure Gate' = $flightInfo.AirlineFlightInfoResult.gate_orig
	  'Arrival Terminal' = $flightInfo.AirlineFlightInfoResult.terminal_dest
	  'Arrival Gate' = if ($flightInfo.AirlineFlightInfoResult.gate_dest) {$flightInfo.AirlineFlightInfoResult.gate_dest} else {'n/a'}
	  'Filed Departure Time' = (Get-LocalTime -UTCTime (ConvertFrom-Unixdate $actualflightInfo.filed_departuretime).toString()).toString()
	  'Estimated Arrival Time' = (Get-LocalTime -UTCTime (ConvertFrom-Unixdate $actualflightInfo.estimatedarrivaltime).toString()).toString()
	}

	if ($flightInfo.AirlineFlightInfoResult) {
		$response_body = @{
			text = "$($result | Convertto-Json)"
			response_type = 'in_channel'
		}
	}
	else {
		$response_body = @{
			text = 'Something went wrong with the Flight Status API.'
		}
	}
}

Invoke-RestMethod -Uri $decoded_response_url -Method Post -ContentType 'application/json' -Body (ConvertTo-Json $response_body) -Verbose