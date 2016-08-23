var postData = querystring.stringify({
    'icao': 'ymml'
});

var options = {
    hostname: "https://dogithub.azurewebsites.net/api/metarSlackbot?icao=${postdata.icao}",
    port: 443,
    method: 'Get',
    headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
    }
};

var req = http.request(options, (res) => {
    console.log(`STATUS: ${res.statusCode}`);
    console.log(`HEADERS: ${JSON.stringify(res.headers)}`);
    res.setEncoding('utf8');
    res.on('data', (chunk) => {
        console.log(`BODY: ${chunk}`);
    });
    res.on('end', () => {
        console.log('No more data in response.');
    });
});

req.on('error', (e) => {
    console.log(`problem with request: ${e.message}`);
});

// write data to request body
req.write(postData);
req.end();
