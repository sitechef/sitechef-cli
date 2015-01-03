###
# Upload Template Files
#
# Reads each template file in the 'templates'
# directory and sends file in body
# of a PUT request to themes api server
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

FindAndUpload = require '../utilities/FindAndUpload'

FetchJSON = require '../utilities/FetchJSON'
Defaults = require '../defaults'

###
# @param {String} theme root
# @param {String} apikey
# @param {Function} callback
# @param {Boolean} just return the class (for testing)
###

module.exports = (themeRoot, apiKey, callback, classOnly =false)->
  class UploadTemplateFiles extends FindAndUpload

    glob: '**/*.html'

    endpoint: 'html'
    baseDir: 'templates'

    ###
    # Make a DELETE request
    # to Theme Api to remove
    # previous template files first
    # @param {Function} callback (err)
    ###
    beforeStart: (cb) =>
      config = Defaults false
      url = config.themesHost + @endpoint
      @log "Removing existing template files"
      FetchJSON
        method: 'DELETE'
        url: url
        apiKey: @apiKey
      , cb


  if classOnly
    return UploadTemplateFiles

  new UploadTemplateFiles themeRoot, apiKey, callback

