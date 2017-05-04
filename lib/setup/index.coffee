###
# Generates the sitechef config file
# and downloads and updates the data snapshot
#
# @copyright Campbell Morgan, SiteChef, 2015
# @author Campbell Morgan <dev@sitechef.co.uk>
###

ServiceMeta = require '../initialiser/writeServiceMeta'
SaveSnapshot = require '../initialiser/saveSnapshotFile'

async = require 'async'
path = require 'path'
fs = require 'fs'

###
# @param {String} theme root
# @param {String} api key
###
module.exports = (themeRoot, apiKey) ->

  siteChefDir = path.join themeRoot, '.sitechef'

  # write config file
  async.auto

    checkDirectory: (cb) ->
      fs.readdir siteChefDir
      , (err, res) ->
        return cb(null, false) if err
        cb(null, true)

    makeDirectory: ['checkDirectory', (results, cb) ->
      return cb() if results.checkDirectory
      fs.mkdir siteChefDir, cb
    ]

    writeMeta: ['makeDirectory', (results, cb) ->
      ServiceMeta apiKey, themeRoot, cb
    ]

    saveSnapshot: ['makeDirectory', (results, cb) ->
      dest = path.join siteChefDir
      , 'data.json'

      SaveSnapshot apiKey, dest, themeRoot
      , cb
    ]

  , (er, results) ->

    throw new Error(er) if er

    console.log "\n\n Directory created and data file created successfully"
