Function Get-ICAOCode {
  param (
    $iata
  )
  # status Y means current data
  $Fields = @{"status" = "Y"; "iataairl" = "$iata"}
  $avcode = Invoke-RestMethod -Uri "http://avcodes.co.uk/airlcoderes.asp" -Method Post -Body $Fields -Verbose
  $regex = 'ICAO Code:<br />&nbsp;\D{3}'
  $avcode -match $regex
  $airline_icao = ($Matches[0]).Split(';')[1].SubString(0,3)
  $airline_icao
}

Function ConvertFrom-Unixdate ($UnixDate) {
  [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
}

# http://blog.tyang.org/2012/01/11/powershell-script-convert-to-local-time-from-utc/
Function Get-LocalTime($UTCTime) {
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

Function Get-ETD {
  param (
    [Parameter(Mandatory=$true)]
    [string]$filed_ete,
    [Parameter(Mandatory=$true)]
    [string]$eta
  )
  $textReformat = $flightInfoEx.filed_ete -replace ",","."
  $seconds = ([TimeSpan]::Parse($textReformat)).TotalSeconds 
  $eta.AddSeconds(-($seconds))
}

Function Set-AuthenticationHeader {

  $pair = "$($env:flightaware_user):$($env:flightaware_api)"
  $encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
  $basicAuthValue = "Basic $encodedCreds"
  $Headers = @{
    Authorization = $basicAuthValue
  }
  $Headers
}

Function Get-FlightInfo {
  param (
    [Parameter(Mandatory=$true)]
    [string]$today,
    [Parameter(Mandatory=$true)]
    [string]$tomorrow,
    [Parameter(Mandatory=$true)]
    [string]$airline_icao,
    [Parameter(Mandatory=$true)]
    [string]$flightno
  )
  Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirlineFlightSchedules?startDate=$($today)&endDate=$($tomorrow)&airline=$($airline_icao)&flightno=$($flightno)" -Headers $Headers -Verbose
}

Function Send-SlackResponse {
  param (
    $decoded_response_url,
    $response_body
  )
  Invoke-RestMethod -Uri $decoded_response_url -Method Post -ContentType 'application/json' -Body (ConvertTo-Json $response_body) -Verbose
}

Function Convert-ICAOtoIATA {
  param (
    [Parameter(Mandatory=$true)]
    [string]$icao
  )
  Invoke-RestMethod -Method Get -Uri http://www.airport-data.com/api/ap_info.json?icao=$icao | ConvertTo-Json
}

Function Get-FlightInfoEx {
  param (
    [Parameter(Mandatory=$true)]
    [string]$flightident,
    [Parameter(Mandatory=$true)]
    $Headers
  )
  Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/FlightInfoEx?ident=$($flightident)&howMany=2" -Headers $Headers -Verbose
}

Function Get-AirportInfo {
  param (
    [Parameter(Mandatory=$true)]
    [string]$airportcode
  )
  Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirportInfo?airportCode=$($airportcode)" -Headers $Headers -Verbose
}

Function Get-AirlineFlightInfo {
  param (
    $faFlightID
  )
  Invoke-RestMethod -Method Get -Uri "https://flightxml.flightaware.com/json/FlightXML2/AirlineFlightInfo?faFlightID=$(faFlightID)" -Headers $Headers -Verbose
} 