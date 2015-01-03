###
# Downloads and unzips the template
# files
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
Defaults = require '../defaults'

path = require 'path'

###
# @param {String} apiKey
# @param {String} Destination Directory
# @param {Function} callback (err, destinationDirectory)
# @param {Overrides} host overrides [optional]
#   {
#     themesHost: {String} hostname
#     enpoint: {String} endpoint override
#   }
###
module.exports = (apiKey, destinationDirectory, callback, overrides) ->

  templatesDir = path.join(
    destinationDirectory
    'templates'
  )

  defaults = Defaults 'htmlZip', overrides

  DownloadUnzip
    description: "Downloading and expanding HTML template files"
    destination: templatesDir
    src: defaults.themesHost + defaults.endpoint
    apiKey: apiKey
  , callback



