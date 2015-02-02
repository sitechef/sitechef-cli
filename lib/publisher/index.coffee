###
# Publish
#
# Co-ordinates publishing of local
# theme back to server
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

fs = require 'fs'
path = require 'path'
async = require 'async'

ClearS3 = require './ClearS3'
UpdateTheme = require './UpdateTheme'
UploadDist = require './UploadDist'
UploadSCSS = require './UploadSCSS'
UploadTemplateFiles = require './UploadTemplateFiles'
UploadZip = require './UploadZip'


module.exports = ->
  class Publisher

    constructor: (themeRoot) ->
      unless themeRoot?
        themeRoot = process.cwd()

      @themeRoot = themeRoot

      @start()

    ###
    # Coordinates process
    ###
    start: =>
      @parseSiteChefFile()
      @parseSiteChefIgnore()

      async.waterfall [
        ((cb) =>
          @clearS3 cb
        )
        ((data, cb) =>
          @updateThemeMetadata cb
        )
        ((data, cb) =>
          @uploadSCSSFiles cb
        )
        ((data, cb) =>
          @uploadDist cb
        )
        ((data, cb) =>
          @uploadTemplateFiles cb
        )
        ((data, cb) =>
          @uploadZip cb
        )

      ], (err, results) ->
        if err
          console.error "PUBLISH FAILED"
          , err
          return

        console.log "PUBLISH SUCCESSFUL"

    ###
    # Reads sitechef file
    # to fetch api key
    ###
    parseSiteChefFile: (test, updateDate = true)=>
      console.log "\nReading Configuration..\n"
      siteChefPath = @configOverride || path.join(
        @themeRoot,
        '.sitechef'
        '.conf'
      )
      try

        @config = JSON.parse(
          fs.readFileSync(siteChefPath)
        )

        @apiKey = @config.code

        @config.lastPublished = if test? then null else new Date()
        # update the published date to now
        if updateDate
          fs.writeFileSync(siteChefPath, JSON.stringify(@config, null, 2))

      catch e
        console.error(
          "Unable to read sitechef config file"
          "Exiting", e
        )
        throw new Error("Unable to read sitechef file")

    ###
    # Parse SiteChef ignore
    # file
    ###
    parseSiteChefIgnore: =>
      console.log "\nReading SiteChef Ignore..\n"
      siteChefPath = @configOverride || path.join(
        @themeRoot,
        '.sitechefrc'
      )

      try
        unless fs.existsSync(siteChefPath)
          console.log("No .sitechefrc file found at", siteChefPath)
          return @ignoreFiles = []

        data = JSON.parse(
          fs.readFileSync(siteChefPath)
        )
        @ignoreFiles = data.ignore

      catch e
        console.error(
          ".sitechefrc file could not be read."
          "Must be valid JSON"
          "Exiting"
        )
        throw new Error("Unable to read .sitechefrc file ")

    ###
    # Clears S3 of all existing theme
    # contents
    #
    # @param {Function} (err, success) ->
    #
    ###
    clearS3: (cb) =>
      @log 'Clearing previous theme'
      ClearS3 @apiKey, cb

    ###
    # Update Theme Metadata
    #
    # Reads theme config file
    # and posts to theme server
    #
    # @param {Function} callback (err) ->
    #
    ###
    updateThemeMetadata: (cb)=>
      @log 'Sending Theme Meta...'
      UpdateTheme @themeRoot, @apiKey, cb

    ###
    # Upload SCSS Files
    # Iterates through each SCSS file in the
    # ./scss folder and uploads it to amazon s3
    #
    # @param {Function} callback(err, totalFiles) ->
    #
    ###
    uploadSCSSFiles: (cb) =>
      @log 'Uploading SCSS files'
      UploadSCSS @themeRoot, @apiKey, cb

    ###
    # Uploads the entire contents
    # of the dist folder to S3
    # @param {Function} callback
    ###
    uploadDist: (cb) =>
      @log 'Publishing dist/ files'
      UploadDist @themeRoot, @apiKey, cb

    ###
    # Uploads all html files to
    # Theme API server
    # @param {Function}
    ###
    uploadTemplateFiles: (cb) =>
      @log 'Publishing html template files'
      UploadTemplateFiles @themeRoot, @apiKey, cb

    ###
    # Zips entire directory into
    # a zip file and uploads to s3
    # @param {Function} callback
    ###
    uploadZip: (cb) =>
      @log 'Zipping Theme directory and uploading'
      UploadZip(
        @ignoreFiles
        @apiKey
        @themeRoot
        cb
      )

    ###
    # Logs output
    ###
    log: (message) ->
      console.log message


