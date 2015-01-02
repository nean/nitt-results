Q = require 'q'
# dev code
#fs = require 'fs'
#count = 0;
wrapper = (request)->
  (options)->
    deferred = do Q.defer
    request options, (err, res, body)->
      #count++;
      #fs.writeFile count+''+'.html', body
      #fs.writeFile count+''+'.txt', JSON.stringify options, true, 2
      if err
        deferred.reject new Error err
      else if res.statusCode isnt 200
        deferred.reject new Error "Invalid response status code #{res.statusCode}"
      else
        deferred.resolve res

    deferred.promise

module.exports = wrapper;
