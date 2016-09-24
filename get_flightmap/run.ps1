$pair = "$($env:flightaware_user):$($env:flightaware_api)"
$encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$Headers = @{
  Authorization = $basicAuthValue
}

$flightid = 'UAE404-1474435916-airline-0095'

$res = Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/MapFlightEx?faFlightID=$($flightid)&mapHeight=1000&mapWidth=1000&show_data_blocks=true&show_airports=true" -Headers $Headers -Verbose

$conv = [System.Convert]::FromBase64String($res.MapFlightExResult)

function ConvertFrom-Base64($string) {   
   $bytes=[System.Convert]::FromBase64String($string)
    #$decoded=[System.Text.Encoding]::UTF8.GetString($bytes)
    $decoded=[System.Text.Encoding]::Default.GetString($bytes)
    
    return $decoded
 }
 

 $decoded_image=ConvertFrom-Base64($res.MapFlightExResult)
 [Byte[]]$bytes_image=[System.Text.Encoding]::Default.GetBytes($decoded_image)
 set-content -encoding byte map.png -value $bytes_image -Force

   $response_body = @{
    text = "$result"
    response_type = 'in_channel'
  }
  
Invoke-RestMethod -Uri $decoded_response_url -Method Post -ContentType 'application/json' -Body (ConvertTo-Json $response_body) -Verbose


Out-File -Encoding Ascii $res -inputObject "$(ConvertTo-Json $response_body)"