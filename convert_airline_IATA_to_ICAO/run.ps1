
$req_query_iata

$Fields = @{"iatacode" = "$req_query_iata"}
$WebResponse = Invoke-RestMethod -Uri "http://www.airlinecodes.co.uk/airlcoderes.asp" -Method Post -Body $Fields -Verbose

$regex = '<TD>\D{3}<\/TD>'

$WebResponse -match $regex

$result = $Matches[0]

Out-File -Encoding Ascii $res -inputObject $result.Substring(4,3)