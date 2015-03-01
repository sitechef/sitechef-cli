###
# Finds a series of files in a directory
# and uploads them to themes api in body
# of PUT call to Themes API Server
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

FetchJSON = require '../utilities/FetchJSON'
Defaults = require '../defaults'
fs = require 'fs'
path = require 'path'
async = require 'async'
_ = require 'lodash'
glob = require 'glob'

class FindAndUpload

    glob: '**/*.s?ss'

    endpoint: 'scss'

    # subdirectory for starting point
    baseDir: 'scss'

    constructor: (@themeRoot, @apiKey, @callback)->
      @start()
      @directoryRoot = path.join(
        @themeRoot
        @baseDir
      )

    ###
    # Coordinates file search
    # and upload
    ###
    start: =>
      async.waterfall [
        ((cb) =>
          @beforeStart cb
        )
        ((body, cb) =>
          @findFiles cb
        )
        ((files, cb) =>
          @uploadFiles files, cb
        )

      ]
      , (err, res) =>
        return @callback(err) if err
        @log "Uploaded all html files"
        @callback null, 'done'

    ###
    # Called before Finding/Uploading
    # begins
    # @param {Function} callback
    ###
    beforeStart: (cb) ->
      cb null, 'done'

    ###
    # Iterates through all files
    # according to the glob
    # @param {Function} Callback (err, files)->
    ###
    findFiles: (cb) =>
      glob @glob
      ,
        cwd: @directoryRoot
      , cb

    ###
    # Iterates through each File
    # and uploads them to
    # @param {Array} list of file paths
    # @param {Function} (err, uploadedFiles)
    ###
    uploadFiles: (files, cb) =>
      # limit concurrent
      # connections to 3
      maxConcurrent = process.env.MAX_CONCURRENT || 3

      currentFile = 0
      unless files.length
        @log "No files found in #{@directoryRoot}"
        return cb()
      async.eachLimit files, maxConcurrent
      , (file, callback) =>
        currentFile++
        @log(
          "Uploading File " +
          "#{file} - " +
          "[#{currentFile} / #{files.length}]"
        )
        counter = 0
        runUpload = false

        doneCb = (err, out) =>
          return callback(null, out) unless err
          counter++
          if counter > 3
            return callback(err)
          # try again
          @log "Retrying #{currentFile}"
          runUpload()

        runUpload = =>
          @uploadFile file, doneCb
        runUpload()

      , cb

    ###
    # Uploads an individual file
    # @param {String} relative file path
    # @param {Function} callback (err, file) ->
    ###
    uploadFile: (file, cb) =>
      @readFile file
      , (err, contents) =>
        return cb(err) if err
        @sendFile file, contents, cb

    ###
    # Reads file contents
    # @param {String} File Path
    # @param {Function} callback
    ###
    readFile: (file, cb) =>
      filePath = path.join(
        @directoryRoot, file
      )

      # read file contents
      fs.readFile filePath, cb

    ###
    # Send File
    # Sends file via PUT to theme api
    # @param {String} relative Path
    # @param {String} file contents
    # @param {Function} callback
    ###
    sendFile: (path, contents, cb) =>
      config = Defaults false
      url = config.themesHost + @endpoint  +
      '/' + path

      FetchJSON
        method: 'PUT'
        apiKey: @apiKey
        body: contents.toString()
        json: false
        url: url
      , cb

    ###
    # Logs output of upload
    ###
    log: (message) ->
      console.log message

module.exports = FindAndUpload

