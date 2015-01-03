###
# Updates Theme Metadata
#
# Reads theme.json file and sends meta and variables
# section to theme api
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

FetchJSON = require '../utilities/FetchJSON'
Defaults = require '../defaults'

fs = require 'fs'
path = require 'path'
async = require 'async'
_ = require 'lodash'

###
# @param {String} theme root
# @param {String} apikey
# @param {Function} callback
# @param {Boolean} just return the class (for testing)
###
module.exports = (themeRoot, apiKey, callback, classOnly =false)->
  class UpdateTheme

    constructor: (@themeRoot, @apiKey, @callback)->

      @start()

    ###
    # Co-ordinates asynchronous processes
    ###
    start: =>
      async.waterfall [
        ( (cb) =>
          @readJSONFile(cb)
        )
        ( (fileContents, cb) =>
          @saveThemeData fileContents, cb
        )
      ], @callback

    ###
    # Reads hte theme.json
    # file
    # @param {Function} callback (err, obj)->
    ###
    readJSONFile: (cb) =>
      filePath = path.join(@themeRoot, 'theme.json')
      noJSONError = new Error(
        "Could not parse JSON in theme file"
      )

      fs.readFile filePath
      , (err, contents) =>
        if err
          console.error(err)
          return cb(noJSONError)
        try
          data = JSON.parse(contents)
        catch e
          return cb(noJSONError)
        cb null, data

    ###
    # Saves meta data
    # @param {Object} JSON File contents
    # @param {Function} callback (err, obj) ->
    ###
    saveThemeData: (data, cb) =>
      data = _.pick data
      , 'meta', 'variables'

      conf = Defaults(false)

      FetchJSON
        method: 'PUT'
        url: conf.themesHost + 'theme'
        apiKey: @apiKey
        body: data
      , cb



  if classOnly
    return UpdateTheme

  new UpdateTheme themeRoot, apiKey, callback
