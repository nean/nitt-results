request = require 'request'
Q = require 'q'

promisifiedRequest = (options)->
  deferred = do Q.defer
  request options, (err, res, body)->
    if err
      deferred.reject new Error err
    else if res.statusCode isnt 200
      deferred.reject new Error "Invalid response status code #{res.statusCode}"
    else
      deferred.resolve res

  deferred.promise

module.exports = promisifiedRequest;
