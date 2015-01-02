results = require './index.js'

_help = (object) ->
  JSON.stringify object, true, 2

if process.argv.length < 2
  console.log "Usage: node cli.js <rollno>"

if null is process.argv[2].match /^\d{9}$/
  console.log "Invalid roll"
  process.exit 1

promise = results.getLatestResult process.argv[2]

promise.then (arr)->
  console.log _help arr

promise.fail (reason)->
  console.log "error", _help reason
