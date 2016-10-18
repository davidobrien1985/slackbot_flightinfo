$request = $req_query_icao

Set-AuthenticationHeader

$decoded_response_url = [System.Web.HttpUtility]::UrlDecode($req_query_callback) 
$decoded_response_url = $decoded_response_url.TrimEnd('"')

Out-File -Encoding Ascii $response -inputObject "$request"

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
($weather.raw_data) -match $regex
$pressure = ($Matches[0]).SubString(1)

# CAVOK?
$regex = 'CAVOK'
if (($weather.raw_data) -match $regex) {
  $CAVOK = $true
}

$result = @"
* ${req_query_user} here is your Weather Info for $(${airport}.name) / ${airport_code}*
    Observation Date = *$((Get-LocalTime -UTCTime ((ConvertFrom-Unixdate $(${weather}.time)).ToString())).ToString())*
  Clouds = $(${weather}.cloud_friendly)
  Clouds altitude = $(if ($CAVOK) {"No clouds below 10,000ft"} else {"$(${weather}.cloud_altitude) ft"})
  Cloud type = $(${weather}.cloud_type)
  Temperature = $(${weather}.temp_air) C
  Pressure = $(${pressure}) hPa
  Wind = $(${weather}.wind_direction) degrees / $(${weather}.wind_speed) kts
  Wind Gusts = $(${weather}.wind_speed_gust) kts
  Visibility = $(${weather}.visibility) m
  Raw Report = $(${weather}.raw_data)
"@

if ($result) {
    $response_body = @{
        text = "$result"
        response_type = 'ephemeral'
    }
}
else {
    $response_body = @{
        text = 'Something went wrong with the weather API.'
    }
}

Invoke-RestMethod -Uri $decoded_response_url -Method Post -ContentType 'application/json' -Body (ConvertTo-Json $response_body) -Verbose