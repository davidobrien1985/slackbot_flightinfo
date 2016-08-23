module.exports = function (context, req) {

    context.log('Request Headers = ', JSON.stringify(req.body));
    var https = require('https');

    var input = JSON.stringify(req.body);
    var icao = input.split('&')[8].split('=')[1];
    var callback = input.split('&')[9].split('=')[1];
    var username = input.split('&')[6].split('=')[1];

    context.log('Input was %s',icao);

    context.response = {
        status: 200, /* Defaults to 200 */
        text: `Hello ${username}, I am getting your weather for ${icao}, try again if you have not heard back in 20s.`
    };

    function getMetar(icaocode) {

        context.log(`https://dogithub.azurewebsites.net/api/metarSlackbot?icao=${icaocode}&callback=${callback}`);

        https.get(`https://dogithub.azurewebsites.net/api/metarSlackbot?icao=${icaocode}&callback=${callback}`, function (res) {
            var body = ''; // Will contain the final response
            // Received data is a buffer.
            // Adding it to our body
            res.on('data', function (data) {
                body += data;
            });
            // After the response is completed, parse it and log it to the console
            res.on('end', function () {
                var parsed = JSON.parse(body);
                context.log(parsed);
            });
        })
            // If any error has occured, log error to console
            .on('error', function (e) {
                context.log("Got error: " + e.message);
            });
    }

    getMetar(icao);

    context.done();
};