###
# Save Snapshot File
#
# Downloads the JSON Data snapshot file
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

Download = require '../utilities/Download'
FetchJSON = require '../utilities/FetchJSON'
Defaults = require '../defaults'
_ = require 'lodash'
fs = require 'fs'
async = require 'async'

###
# @param {String} apiKey
# @param {String} destination path
# @param {String} themeDirectory
# @param {Function} callback (err, destinationPath)
# @param {Object} overrides [optional]
#   {
#     themesHost: 'https://themes.sitechef.co.uk/
#     endpoint: 'datafile'
#   }
###
module.exports = (apiKey, destination, themeDirectory, callback, overrides) ->

  defaults = Defaults 'dataFile', overrides

  imagePathUri = [
    'siteLogo'
    'siteLogo_2x'
    'favicon'
  ]


  async.waterfall [
    # get the signed AWS url for
    # the JSON file
    ((cb) ->
      FetchJSON
        url: defaults.themesHost + defaults.endpoint
        apiKey: apiKey
      , cb
    )
    # download the json
    # file to the .sitechef directory
    ((signedUrl, cb)->
      Download
        description: 'Downloading data snapshot JSON file'
        src: signedUrl
        dest: destination
      , cb
    ),
    ((snapshotFile, cb)->
      # write out the preferences as preference.scss
      snapshot = JSON.parse(fs.readFileSync(snapshotFile))
      preferences = snapshot['/'].preferences
      imageRoot = snapshot['/'].imageRoot
      preferencesSCSS = _.reduce preferences
      , (memo, val, pref) ->
        if _.isString(val)
          content = val.replace /\n/g, ''
          # concatenate image base path
          # with relative path of logo & favicon
          if _.indexOf(imagePathUri, pref) isnt -1
            content = imageRoot + content

          memo+= "$#{pref}:'#{content}';\n"

        memo
      , ''
      fs.writeFileSync themeDirectory + '/prefs.scss'
      , preferencesSCSS
      cb null, snapshotFile

    )
  ], callback

