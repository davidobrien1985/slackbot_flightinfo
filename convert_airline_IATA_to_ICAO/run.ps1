

$Fields = @{"iatacode" = "$req_query_iata"}
$WebResponse = Invoke-RestMethod -Uri "http://www.airlinecodes.co.uk/airlcoderes.asp" -Method Post -Body $Fields
$TD = $WebResponse.AllElements | Where {$_.TagName -eq "TD" }

$regex = '<TD>\D{3}<\/TD>'

foreach ($i in $TD.outerHTML) {
  $i -match $regex
}

$result = $Matches[0]

Out-File -Encoding Ascii $res -inputObject $result.Substring(4,3)