###
# Installs NPM modules for a given
# Directory
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

childProcess = require('child_process').exec
CustomerError = require '../errors/CustomerError'
consts = require '../consts'

fs = require 'fs'
path = require 'path'

async = require 'async'

###
# @param {String}
# @param {Function}
###
module.exports = (directory, callback, logOutput = true) ->

  async.waterfall [
    # read package.json
    ((cb) ->
      fs.readFile path.join(directory, 'package.json')
      , (err, contents) ->
        return cb(CustomerError(
          "Could not read package.json file for theme",
          consts.PACKAGE_JSON_NOT_FOUND
          )
        ) if err
        try
          data = JSON.parse(contents)
        catch e
          return cb(
            CustomerError(
              "Theme package.json corrupted.",
              consts.PACKAGE_JSON_CORRUPT
            )
          )
        cb null, data
    )
    # install all node modules
    ((data, cb) ->
      errorThrown = false
      child = childProcess(
        "npm install --production"
        , cwd: directory
        , (err, stdout, stderr)->
          return cb(new CustomerError(
            "Failed to install package.json dependencies"
            consts.DEPENDENCY_INSTALL_FAIL
          )) if err or errorThrown
          cb()
      )
      # log stderr
      child.stderr.on 'data', (data) ->
        if data.match /ERR/
          errorThrown = true
        if logOutput
          console.error data
      # log stdout
      child.stdout.on 'data', (data) ->
        if logOutput
          console.log data.toString().replace(/\n/g, ' ')
    )
  ], callback

