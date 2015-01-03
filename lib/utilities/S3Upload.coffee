###
# Uploads a file
# to S3 using a supplied policy
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###
request = require 'request'
fs = require 'fs'
async = require 'async'
log = require('single-line-log').stdout

FetchJSON = require './FetchJSON'

class S3Upload

  # number of times to retry
  retryLimit : 2

  ###
  # @constructor
  #
  # @param {String} absolute local file path
  # @param {Object} policy received from server:
  #       {
  #         policy: {String}
  #         signature: {String}
  #         bucket: {String}
  #         key: {String}
  #         acl: {String}
  #         'Content-Type': {String}
  #         AWSAccessId: {String}
  #       }
  # @param {Function} Done Callback
  # @param {String} AWS access control
  ###
  constructor: (@filePath, @policy, @callback, @acl = 'public-read')->
    # number of times retried
    @retried = 0

    @complete = false
    @start()


  ###
  # Begins processing
  ###
  start: =>
    async.waterfall [
      ( (cb) =>
        @getFileSize cb
      )
      ( (fileSize, cb) =>
        @upload fileSize, cb
      )

    ], @callback


  ###
  # Upload form data to S3
  # using request
  # @param {Integer} file size
  # @param {Function} callback
  ###
  upload: (fileSize, cb) =>

    opts = @makeOptions(fileSize)

    @log "Uploading #{@filePath} ..."

    # instantiate the request
    r = request opts
    , (err, message, body)=>
      success = err is null and (
        message.statusCode is 200 or
        message.statusCode is 204
      )
      if success
        @completed = true
        @log "Uploaded #{@filePath} successfully"
        return cb(null, true)

      @log "Failed to upload #{@filePath}"
      , (err || message.statusCode), body

      # retry if below retry limit
      if @retried < @retryLimit
        @log "Retrying"
        @retried++
        return @upload fileSize, cb


      @completed = true
      cb(
        new Error(
          "Failed to upload #{@filePath}"
        )
      )

    @logUpload(r, fileSize) if fileSize > 0


  ###
  # Gets the file size in bytes
  # @param {Function} (err, size) ->
  ###
  getFileSize: (cb) =>
    fs.stat @filePath, (err, stats) ->
      return cb(err) if err
      cb null, stats.size


  ###
  # Creates the request
  # options using s3 policy, signature
  # and file information
  # @return {Object}
  ###
  makeOptions: (fileSize) =>
    url = "https://#{@policy.bucket}" +
      ".s3.amazonaws.com/"

    options =
      method: 'POST'
      url: url
      formData:
        key: @policy.key
        AWSAccessKeyId: @policy.AWSAccessKeyId
        acl: @acl
        policy: @policy.policy
        signature: @policy.signature
        "Content-Type": @policy['Content-Type']
        "Content-Length": fileSize
        file: fs.createReadStream(@filePath)

  # delay in between
  # each upload progress request
  pollDelay: 250

  ###
  # Gets Percent complete of upload
  # @param {Request}
  # @param {Integer} total filesize
  ###
  getPercent: (request, fileSize) =>
    return 101 if @completed
    return 0 unless 'req' of request
    return 0 unless 'connection' of request.req
    return 0 if parseInt(fileSize) is 0
    sent = parseInt(
      request.req.connection._bytesDispatched
    )
    Math.ceil(
      (sent / fileSize) * 100
    )


  ###
  # Writes out percentage of upload
  # to stdout
  # @param {Request} request object
  # @param {Int} total filesize
  ###
  logUpload: (request, fileSize) =>
    percent = @getPercent request, fileSize
    return if percent > 100
    msg = "#{@filePath} [#{percent}%]"
    @singleLineLog msg

    return if percent is 100

    setTimeout =>
      @logUpload request, fileSize
    , @pollDelay


  log: (message, err) ->
    console.error(err) if err?
    console.log message

  ###
  # Single line logs
  # @param {String}
  ###
  singleLineLog: (message) =>
    return
    return if process.env.TEST_ACTIVE
    log message

module.exports = S3Upload
