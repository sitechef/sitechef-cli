###
# Updates The data.json File
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###
Publisher = require('../publisher/')()
SaveSnapshot = require '../initialiser/saveSnapshotFile'

path = require 'path'

class ReadConfig extends Publisher
  constructor: (@themeRoot)->

  read: =>
    @parseSiteChefFile(null, false)
    @apiKey

###
# Reads the snapshot file
# then attempts to download
# the snapshot file
# @param {String} themeRoot path
###
module.exports = (themeRoot) ->

  # try and read the .sitechefrc
  readConfig = new ReadConfig(themeRoot)

  apiKey = readConfig.read()

  # now download config file
  dataDestination = path.join(
    themeRoot, '.sitechef'
    , 'data.json'
  )
  SaveSnapshot apiKey, dataDestination
  , themeRoot
  , (err, result) ->
    if err
      throw err

    console.log "Data file updated successfully"




