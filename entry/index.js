module.exports = function (context, req) {

    var http = require('http');
    var icao = (req.query.icao);

    context.log('Input was %s',icao);

    // $decoded_response_url = [System.Web.HttpUtility]::UrlDecode(((Get - Content $req - Raw).Split('&')[9]).Split('=')[1]) 
    // $decoded_response_url

    function getMetar(icaocode) {

        console.log(`https://dogithub.azurewebsites.net/api/metarSlackbot?icao=${icaocode}`);
        return http.get({
            host: `https://dogithub.azurewebsites.net/api/metarSlackbot?icao=${icaocode}`,
        });
    }

    getMetar(icao);

    context.done();
};