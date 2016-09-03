module.exports = function (context, req) {
    
    var https = require('https');

    var input = JSON.stringify(req.body);
    var userquery = input.split('&')[8].split('=')[1];
    var callback = input.split('&')[9].split('=')[1];
    var username = input.split('&')[6].split('=')[1];

    // define function to call other Azure function to get the weather
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

    context.log('Input was %s', userquery);
    context.log('%s', userquery.length);

    // define regexpattern for IATA or ICAO airport codes, either 3 or 4 letters allowed
    var regexpattern = /^[a-zA-Z]+$/;


    if ((userquery.length == 3 || userquery.length == 4) && regexpattern.test(userquery)) {

        context.bindings.response = `Hello ${username}, I am getting your weather for ${userquery}, try again if you have not heard back in 20s.`;

        getMetar(userquery);

        context.done();
    }
};