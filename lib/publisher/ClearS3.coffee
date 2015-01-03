###
# Clear S3
#
# Sends a request to themes api to clear
# existing content on s3
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

###
#
# @param {String} api code
# @param {Function} callback on done (err) ->
#
###

FetchJSON = require '../utilities/FetchJSON'
Defaults = require '../defaults'

module.exports = (apiCode, callback) ->
  config = Defaults false

  # perform DELETE request on themes core
  FetchJSON
    method: 'DELETE'
    url: config.themesHost + 'theme'
    apiKey: apiCode
  , callback

