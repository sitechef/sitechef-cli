###
# Write Service Meta
#
# Writes the the service metadata json file
# to the .sitechef directory
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

path = require 'path'
fs = require 'fs'

###
# @param {String} api code for this theme
# @param {String} theme folder
# @param {Function} (err, filePath) callback on done
###
module.exports = (apiCode, themeFolder, callback) ->
  jsonFileData =
    code: apiCode
    createdAt: new Date()
    lastPublished: false

  fileDestination = path.join(themeFolder, '.sitechef', '.conf')
  fs.writeFile fileDestination
  , JSON.stringify(jsonFileData, null, 2)
  , (err, result) ->
    return callback(err) if err
    callback null, fileDestination

