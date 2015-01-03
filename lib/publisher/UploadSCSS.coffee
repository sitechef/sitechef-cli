###
# Uploads All SCSS Files to themes Server
#
# Iterates through directory finding all SCSS
# files and uploading them to the Themes API Server
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

###
# @param {String} theme root
# @param {String} apikey
# @param {Function} callback
# @param {Boolean} just return the class (for testing)
###

module.exports = (themeRoot, apiKey, callback, classOnly =false)->
  class UploadSCSS extends FindAndUpload

    glob: '**/*.s?ss'

    baseDir: 'scss'
    endpoint: 'scss'

  if classOnly
    return UploadSCSS

  new UploadSCSS themeRoot, apiKey, callback
