$request = $req_query_icao

$decoded_response_url = [System.Web.HttpUtility]::UrlDecode($req_query_callback) 
$decoded_response_url = $decoded_response_url.TrimEnd('"')

Out-File -Encoding Ascii $response -inputObject "$request"

$pair = "$($env:flightaware_user):$($env:flightaware_api)"
$encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
  Authorization = $basicAuthValue
}

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

switch ($request.Length) {
    3 {
        $airport_code = (Invoke-RestMethod -Method Get -Uri https://dogithub.azurewebsites.net/api/get_ICAO_from_IATA?code=$request).icao
    }
    4 {
        $airport_code = $request
    }
    default {
        $res = 'Invalid Airport code'
    }
}

$airport_code = ($airport_code).ToUpper()
$weather = (Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/MetarEx?airport=$($airport_code)&howMany=1" -Headers $Headers -Verbose).MetarExResult.metar
$airport = (Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirportInfo?airportCode=$($airport_code)" -Headers $Headers -Verbose).AirportInfoResult

# Get air pressure in hPa
$regex = 'Q\d{4}'
($weather.MetarExResult.metar.raw_data) -match $regex
$pressure = $Matches[0]

# CAVOK?
$regex = 'CAVOK'
if (($weather.MetarExResult.metar.raw_data) -match $regex) {
	$CAVOK = $true
}

$result = @"
Weather Info for $(${airport}.name) / ${airport_code}
Observation Date = *$((Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${weather}.time)).ToString())).ToString())*
Clouds = $(${weather}.cloud_friendly)
Clouds altitude = $(if ($CAVOK) {"No clouds below 10,000ft"} else {$(${weather}.cloud_altitude)})
Cloud type = $(${weather}.cloud_type)
Temperature = $(${weather}.temp_air) C
Pressure = $(${pressure}) hPa
Wind = $(${weather}.wind_direction) degrees / $(${weather}.wind_speed) kts
Wind Gusts = $(${weather}.wind_speed_gust) kts
Visibility = $(${weather}.visibility)
"@

if ($result) {
    $response_body = @{
        text = "$result"
        response_type = 'in_channel'
    }
}
else {
    $response_body = @{
        text = 'Something went wrong with the weather API.'
    }
}

Invoke-RestMethod -Uri $decoded_response_url -Method Post -ContentType 'application/json' -Body (ConvertTo-Json $response_body) -Verbose