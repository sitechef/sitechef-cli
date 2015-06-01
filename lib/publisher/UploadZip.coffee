###
# Uploads A Zip File
# Containing the essential build
# contents of the theme
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
#
###
_ = require 'lodash'
archiver = require 'archiver'
temp = require 'temp'
async = require 'async'
fs = require 'fs'

FetchJSON = require '../utilities/FetchJSON'
Defaults = require '../defaults'
S3Upload = require '../utilities/S3Upload'

###
# @param {Array} List of files to ignore
# @param {String} Api Key
# @param {String} absolute path of theme root
# @param {Function} (err, zipfile)
# @param {Boolean} just return the class (for testing)
###
module.exports = (
  ignoreFiles, apiKey, themeRoot
  , callback, classOnly
) ->

  class UploadZip

    ###
    # List of paths
    # to always ignore
    ###
    alwaysIgnore: [
      '.sitechef'
      'node_modules'
      "templates"
      "prefs.scss"
      '.git'
    ]

    S3Upload: S3Upload

    constructor: (ignoreFiles, @apiKey, @themeRoot, @callback)->

      # combine ignore files
      @setupIgnore ignoreFiles

      @start()

    ###
    # Setup ignore list
    # @param {Array} customer ignore files
    ###
    setupIgnore: (files) =>
      ignoreList = _.union files, @alwaysIgnore
      # convert the list into regular expressions
      @ignore = _.map ignoreList, (item) ->
        # replace any "*" in the glob
        # with [^\/\\\\]*
        item = item.replace("*", "[^\/\\\\]*")

        new RegExp("[\/\\\\]#{item}($|[\/\\\\])")

    ###
    # Coordinates subfunctions
    ###
    start: =>
      async.auto

        zip: (cb) =>
          @buildZip cb

        policy: (cb) =>
          @getPolicy cb

        upload: [
          'zip'
          "policy"
          (cb, results) =>
            @uploadToS3(
              results.policy
              results.zip
              cb
            )
        ]

        cleanup: [
          "upload"
          (cb, results) =>
            @cleanup cb
        ]
      , (err, results) =>
        # if there's an error
        # cleanup the temp file
        # before finishing
        if err
          return @cleanup =>
            @callback err

        @callback null, results

    ###
    # Filter function
    # used by node archiver
    # to process ignore files
    ###
    filterFile: (path) =>
      _.reduce @ignore, (memo, ignoreRegExp) ->
        return memo unless memo

        not path.match(ignoreRegExp)

      , true

    ###
    # Builds the zip file
    # @param {Function} callback (err, destination)
    ###
    buildZip:  (cb) =>
      temp.track()
      archive = archiver('zip')
      archive.bulk [
        {
          expand: true
          filter: (src) =>
            @filterFile(src)
          cwd: @themeRoot
          src: ['**','.**']
        }
      ]
      tempZip = temp.createWriteStream
        suffix: '.zip'

      archive.on 'error', (err) ->
        cb err

      tempZip.on 'close', ->
        cb null, tempZip

      # connect archive out to
      # writeable stream
      archive.pipe(tempZip)

      # finalize the zip file
      archive.finalize()

    ###
    # Get the policy for the zip
    # file in order to upload it to s3
    ###
    getPolicy: (cb) =>
      config = Defaults false
      url = config.themesHost + 'srczip'
      if process.env.DEBUG_MODE
        callback = (err, res) ->
          console.log('Debug: getpolicy zip', err, res)
          cb(err, res)
      else
        callback = cb
      FetchJSON
        method: 'PUT'
        url: url
        apiKey: @apiKey
      , callback

    ###
    # Upload created zip file to S3
    # @param {Object} policy
    # @param {WriteableStream}
    # @param {Function} callback
    ###
    uploadToS3: (policy, tempFile, cb) =>
      s3 = new @S3Upload tempFile.path
      , policy
      , cb
      , 'private'

    ###
    # Removes zip file
    # @param {Function} cb
    ###
    cleanup: (cb) ->
      temp.cleanup cb

  if classOnly
    return UploadZip

  new UploadZip(
    ignoreFiles
    apiKey
    themeRoot
    callback
  )
