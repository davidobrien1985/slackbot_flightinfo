module.exports = function (context, req) {

    var http = require('http');
    var icao = (req.query.icao);

    context.log('Input was %s',icao);

    function getMetar(output) {

        return http.get({
            host: `https://dogithub.azurewebsites.net/api/metarSlackbot?icao=${icao}`,
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
    context.done();
};