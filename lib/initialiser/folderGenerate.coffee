###
# Folder Generator
#
# Creates the initial directory
# for the user and the .sitechef subdirectory
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
async = require 'async'
Defaults = require '../defaults'
FetchJSON = require '../utilities/FetchJSON'
_ = require 'lodash'

###
# @param {Object} config -
#   {
#     rootPath: {String} current working directory
#     directoryOverride: {String|Boolean}
#           override for directory name
#     apiKey: {String} api key for theme server
#   }
# @param {Function} (err, themeMetaData) ->
#          called on completion/error
# @param {Boolean} if true, returns unitialised
#                  class for testing
###
module.exports = (config, cb, dev = false, overrides) ->

  class FolderGenerate

    defaults:
      rootPath: process.cwd()
      directoryOverride: false

    ###
    # @constructor
    # @param {Object} configuration overrides for defaults
    # @param {Function} callback
    ###
    constructor: (config, @cb) ->
      @opts = _.extend {}, @defaults
      _.extend @opts, config

      @themeMeta = false

      @generate()

    generate: =>
      @getMeta (meta) =>
        folderName = @_generateFolderName()
        @_mkdir folderName

    ###
    # Gets the metadata from
    # theme server
    ###
    getMeta: (cb) =>
      defaults = @_getDefaults()
      FetchJSON
        url: defaults.themesHost + defaults.endpoint
        apiKey: @opts.apiKey
      , (err, meta) =>
        return @cb(err) if err
        @themeMeta = meta
        cb meta

    _getDefaults: () ->
      Defaults 'themeMeta', overrides

    ###
    # Checks the folder name
    ###
    _generateFolderName: =>
      if @opts.directoryOverride
        return @opts.directoryOverride
      # no default name so
      # convert theme name to
      # lowercase and add hyphens
      # for spaces

      # lowercase version
      name = @themeMeta.meta.name.toLowerCase()

      # replace all spaces with hyphens
      name = name.replace /\ /g, '-'
      # replace all non traditional letters/digits
      # with _
      name.replace /[^a-z0-9\-\_]/g, '_'

    ###
    # Creates the folder
    # and executes the callback
    ###
    _mkdir: (folderName) =>
      destinationPath = path.join(
        @opts.rootPath
        folderName
      )
      siteChefDir = path.join(
        destinationPath
        '.sitechef'
      )
      fs.mkdir destinationPath
      , (err, result) =>
        return @cb(err) if err
        fs.mkdir siteChefDir, (err, result) =>
          return @cb(err) if err
          @cb null
          ,
            theme: @themeMeta
            path: destinationPath



  if dev
    return FolderGenerate

  new FolderGenerate(config, cb)

