module.exports = function (context, req) {

    var http = require('http');
    var icao = (req.query.icao);

    context.log('Input was %s',icao);

    // $decoded_response_url = [System.Web.HttpUtility]::UrlDecode(((Get - Content $req - Raw).Split('&')[9]).Split('=')[1]) 
    // $decoded_response_url

    function getMetar(icaocode) {

        context.log(`https://dogithub.azurewebsites.net/api/metarSlackbot?icao=${icaocode}`);

        http.get(`https://dogithub.azurewebsites.net/api/metarSlackbot?icao=${icaocode}`, function (res) {
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