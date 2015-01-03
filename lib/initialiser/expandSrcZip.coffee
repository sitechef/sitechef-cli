###
# Expand Src Zip
#
# Downloads and expands the zip file
# of the previous theme's file structure
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

DownloadUnzip = require '../utilities/DownloadUnzip'
FetchJSON = require '../utilities/FetchJSON'
Defaults = require '../defaults'

async = require 'async'

###
# @param {String} apiKey
# @param {String} destination directory
# @param {String} destination for zip file
# @param {Function} callback (err, destinationPath)
# @param {Object} overrides [optional]
#   {
#     themesHost: 'https://themes.sitechef.co.uk/
#     endpoint: 'datafile'
#   }
###
module.exports = (
  apiKey, destination, zipPath
  , callback, overrides
) ->

  defaults = Defaults 'srcZip', overrides

  async.waterfall [
    # get the signed AWS url for
    # the JSON file
    ((cb) ->
      FetchJSON
        url: defaults.themesHost + defaults.endpoint
        apiKey: apiKey
      , cb
    )
    ((signedUrl, cb) ->
      DownloadUnzip
        description: "Downloading theme development zip file"
        destination: destination
        zipSaveLocation: zipPath
        src: signedUrl
        apiKey: apiKey
      , cb
    )
  ], callback

