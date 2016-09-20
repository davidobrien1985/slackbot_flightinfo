
$req_query_iata

# status Y means current data
$Fields = @{"status" = "Y"; "iataairl" = "$req_query_iata"}
$WebResponse = Invoke-RestMethod -Uri "http://avcodes.co.uk/airlcoderes.asp" -Method Post -Body $Fields -Verbose

$regex = 'ICAO Code:<br />&nbsp;\D{3}'

$WebResponse -match $regex
$result = $Matches[0]

Out-File -Encoding Ascii $res -inputObject $result.Split(';')[1]