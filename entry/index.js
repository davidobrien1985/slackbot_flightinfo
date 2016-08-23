module.exports = function (context, req) {

    var http = require('http');
    var icao = (req.query.icao);

    context.log('Input was %s',icao);

    // $decoded_response_url = [System.Web.HttpUtility]::UrlDecode(((Get - Content $req - Raw).Split('&')[9]).Split('=')[1]) 
    // $decoded_response_url

    function getMetar(icaocode) {

        return http.get({
            host: `https://dogithub.azurewebsites.net/api/metarSlackbot?icao=${icaocode}`,
        }, function (response) {
            // Continuously update stream with data
            var body = '';
            response.on('data', function (d) {
                body += d;
            });
            response.on('end', function () {

                // Data reception is done, do whatever with it!
                var parsed = JSON.parse(body);
                output({
                    body: parsed
                });
            });
        });
    }

    getMetar(icao);

    context.done();
};