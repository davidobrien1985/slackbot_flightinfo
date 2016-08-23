#$in = Get-Content $req -Raw

#$in.Split('&')[2].Split('=')[1]
#$in.Split('&')[6].Split('=')[1]
#$in.Split('&')[8].Split('=')[1]
$request = $req_name_icao
$decoded_response_url = [System.Web.HttpUtility]::UrlDecode(((Get-Content $req -Raw).Split('&')[9]).Split('=')[1]) 
$decoded_response_url

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

$airport_code
$res = Invoke-RestMethod -Method Get -Uri "http://avwx.rest/api/metar.php?station=$airport_code&format=JSON&options=translate,info" -verbose

if ($res) {
    $response_body = @{
        text = "Weather for $($res.Info[0].City) $($res.Info[0].Name) / $airport_code : $($($res.Translations[0]) | ConvertTo-Json)"
        response_type = 'in_channel'
    }
}
else {
    $response_body = @{
        text = 'Something went wrong with the weather API.'
    }
}
$res.Translations[0] | ConvertTo-Json

Invoke-RestMethod -Uri $decoded_response_url -Method Post -ContentType 'application/json' -Body (ConvertTo-Json $response_body) -Verbose