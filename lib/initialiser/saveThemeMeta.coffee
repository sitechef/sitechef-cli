###
# Downloads and stores Theme Meta Data
# in the theme.json file
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
fs = require 'fs'
path = require 'path'


###
# @param {Object} Theme Metadata to be written to file
# @param {String} destination directory
# @param {Function} callback (err, destinationPath)
###
module.exports = (themeMeta, destination, callback) ->

  filePath = path.join(destination, 'theme.json')
  # write the file to the destination path
  # as formatted json
  fs.writeFile filePath
  , JSON.stringify(themeMeta, null, 2)
  , (err, res) ->
    return callback(err) if err
    callback null, filePath

