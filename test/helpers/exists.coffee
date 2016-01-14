###
# catch file exists exceptions
###
fs = require 'fs'
module.exports = (path) ->
  exists = true
  try
    fs.accessSync(path)
  catch e
    exists = false

  exists
