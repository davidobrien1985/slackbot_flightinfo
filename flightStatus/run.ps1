$in = Get-Content $req -Raw

$in.Split('&')[2].Split('=')[1]
$in.Split('&')[6].Split('=')[1]
$in.Split('&')[8].Split('=')[1]
$request = $in.Split('&')[8].Split('=')[1]

Out-File -Encoding Ascii $response -inputObject "$request"

$pair = "$($env:flightaware_user):$($env:flightaware_api)"
$encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
  Authorization = $basicAuthValue
}

$flightInfoEx = Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/FlightInfoEx?ident=$($request)&howMany=2" -Headers $Headers -Verbose
$flightId = $flightInfoEx.FlightInfoExResult.flights[1].faFlightID


$flightInfo = Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirlineFlightInfo?faFlightID=$flightId" -Headers $Headers -Verbose
$flightInfo.AirlineFlightInfoResult

$decoded_response_url = [System.Web.HttpUtility]::UrlDecode(($in.Split('&')[9]).Split('=')[1]) 
$decoded_response_url

if ($flightInfo.AirlineFlightInfoResult) {
    $response_body = @{
        text = $flightInfo.AirlineFlightInfoResult
        response_type = 'in_channel'
    }
}
else {
    $response_body = @{
        text = 'Something went wrong with the Flight Status API.'
    }
}

Invoke-RestMethod -Uri $decoded_response_url -Method Post -ContentType 'application/json' -Body (ConvertTo-Json $response_body) -Verbose