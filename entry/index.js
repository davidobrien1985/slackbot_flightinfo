module.exports = function (context, req) {

    var http = require('http');
    var icao = (req.query.icao);

    context.log('Input was %s',icao);

    var options = {
        hostname: `https://dogithub.azurewebsites.net/api/metarSlackbot?icao=${icao}`,
        method: 'Get',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        }
    };

    var request = http.request(options, (res) => {
        context.log(`STATUS: ${res.statusCode}`);
        context.log(`HEADERS: ${JSON.stringify(res.headers)}`);
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
            console.log(`BODY: ${chunk}`);
        });
        res.on('end', () => {
            context.log('No more data in response.');
        });
    });

    request.on('error', (e) => {
        context.log(`problem with request: ${e.message}`);
    });

    context.done();
};