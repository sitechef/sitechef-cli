###
# Initialiser
#
# Creates the directory structure
# and populates data
# for user template
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

# External Modules
async = require 'async'
deepExtend = require 'deep-extend'
path = require 'path'

ExpandSrcZip = require './expandSrcZip'
FolderGenerate = require './folderGenerate'
SaveThemeMeta = require './saveThemeMeta'
InstallNode = require './installNodeModules'
SaveSnapshot = require './saveSnapshotFile'
SaveTemplateFiles = require './saveTemplateFiles'
WriteServiceMeta = require './writeServiceMeta'



###
# @param {Object} Configuration
#   {
#     themeDirectory: {String} absolute path for folder generation
#     themeOverride: {String} override for the theme subdir
#     templateDirectory: {String} html templates subfolder
#     srcZip: {String} location fo the src zip
#     apiKey: {String} the api key for this theme
#   }
# @param {Function} callback (error, result)
###
module.exports = (config, callback, classOnly = false) ->
  class Initialiser

    defaults:
      themeDirectory: false
      themeOverride: false
      templateDirectory: 'templates'
      srcZip: ['.sitechef','src.zip']
      snapshotPath: ['.sitechef','data.json']
      apiKey: false

    constructor: (config, @callback) ->
      @opts = deepExtend {}, @defaults, config
      unless @opts.themeDirectory
        throw new Error(
          "No theme directory specified"
        )
      @start()

    ###
    # Iterates through
    # each of the component parts
    # of setting up the theme directory
    ###
    start: =>
      async.auto

        generateFolder: (cb) =>
          @generateFolder cb

        saveMeta: ['generateFolder', (results, cb) =>
          @saveMeta results.generateFolder, cb
        ]

        expandSrcZip: ['generateFolder', (results, cb) =>
          @expandSrcZip results.generateFolder.path, cb
        ]

        saveSnapshot: ['generateFolder', (results, cb) =>
          @saveSnapshot results.generateFolder.path, cb
        ]

        writeServiceMeta: ['generateFolder', (results, cb) =>
          @writeServiceMeta results.generateFolder.path, cb
        ]

        saveTemplateFiles: ['generateFolder', (results, cb) =>
          @saveTemplateFiles results.generateFolder.path, cb
        ]

        installModules: ['expandSrcZip', (results, cb) =>
          @installModules results.generateFolder.path, cb
        ]

      , (err, results) =>
        if err
          return @handleError err
        @callback null, results

    ###
    # Generates folder
    ###
    generateFolder: (cb) =>
      FolderGenerate
        rootPath: @opts.themeDirectory
        directoryOverride: @opts.themeOverride
        apiKey: @opts.apiKey
      , cb


    ###
    # @param {Object}
    #   {
    #     path: {String} absolute path to theme dir
    #     theme: {Object} theme meta data
    #   }
    # @param {Function} callback
    ###
    saveMeta: (data, cb) ->
      SaveThemeMeta data.theme, data.path, cb

    ###
    # @param {String} directory path
    # @param {Function} callback
    ###
    expandSrcZip: (directory, cb) =>
      dest = @generateDirectory(
        directory
        @opts.srcZip
      )

      ExpandSrcZip(
        @opts.apiKey
        directory
        dest
        cb
      )

    ###
    # @param {String} directory path
    # @param {Function} callback
    ###
    saveSnapshot: (directory, cb) =>
      dest = @generateDirectory(
        directory
        @opts.snapshotPath
      )
      SaveSnapshot @opts.apiKey
      , dest
      , directory
      , cb

    ###
    # Downloads and extracts
    # all template files
    # @param {String} directory path
    # @param {Function} callback
    ###
    saveTemplateFiles: (directory, cb)=>
      SaveTemplateFiles @opts.apiKey
      , directory
      , cb

    ###
    # @param {String} directory path
    # @param {Function} callback
    ###
    writeServiceMeta: (directory, cb) =>
      WriteServiceMeta @opts.apiKey
      , directory
      , cb

    ###
    # @param {String} directory path
    # @param {Function} callback
    ###
    installModules: (directory, cb) =>
      InstallNode directory, cb

    ###
    # Generate directory
    # @param {String} rootDir
    # @param {Array|String} extra path
    ###
    generateDirectory: (root, extra) ->
      extra = [extra] if typeof extra is 'string'
      root = [root]

      result = root.concat(extra)
      path.join.apply @, result

    ###
    # Handles Errors thrown in process
    ###
    handleError: (err) =>
      # if it's a customer error
      # write out message and exit
      if err and 'name' of err and err.name is 'CustomerError'
        console.error err.message
        return process.exit()

      # otherwise callback error
      @callback err

  if classOnly
    return Initialiser

  new Initialiser config, callback
