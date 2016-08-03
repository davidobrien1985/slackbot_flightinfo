$result = Invoke-RestMethod -Method Get -Uri http://www.airport-data.com/api/ap_info.json?iata=$req_query_code | ConvertTo-Json
$result
Out-File -Encoding Ascii $res -inputObject "$result"