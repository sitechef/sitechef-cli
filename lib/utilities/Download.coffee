###
# Downloads a file to a destination
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
request = require 'request'
progress = require 'request-progress'
deepExtend = require 'deep-extend'
log = require('single-line-log').stdout

###
# @param {Object} configuration
#   {
#     description: {String|Boolean} optional
#                     description for log
#     src: {String} src url
#     dest:{String} local file path (absolute)
#     apiKey: {String|Boolean} api code for header
#   }
# @param {Function} callback (err, destinationPath)
# @param {Boolean} just return the class (for testing)
###
module.exports = (config, callback, classOnly = false)->

  class Download

    defaults:
      description: false
      src: false
      dest: false
      apiKey: false

    constructor: (config, @callback) ->
      @opts = deepExtend {}, @defaults, config
      @download(@callback)

    ###
    # Downloads a file and saves to disk
    #
    # @param {Function} callback (err, destinationPath)
    # @param {String|Boolean} destination override
    ###
    download: (cb, destination = false) =>

      destination = @opts.dest unless destination

      src = @opts.src
      @getProgress(src)
        .on('response', (response) ->
          if response.statusCode isnt 200
            @emit 'error'
            , new Error(
              "Failed to download file " +
              "(#{src}): Status #{response.statusCode}"
            )
        ).on('error', cb)
        .on('progress', (state) =>@writeProgress(state))
        .pipe(fs.createWriteStream(destination))
        .on('error', cb)
        .on 'close', (err) ->
          return cb(err) if err
          cb null, destination

    ###
    # Writes out the progress
    # to the cli
    # @param {Object} state
    ###
    writeProgress: (state) =>
      description = if @opts.description
      then @opts.description
      else 'Downloading zip file '

      message = "#{description} [#{state.percent}%]"
      @log message

    ###
    # Gets an instance of onProgress
    ###
    getProgress: (src) =>
      headers = if @opts.apiKey
      then {"X-Api-Auth": @opts.apiKey}
      else {}
      options =
        url: src
        headers: headers
      progress(request(options), {})

    ###
    # Single line logs
    # @param {String}
    ###
    log: (message) =>
      return if process.env.TEST_ACTIVE
      log message


  if classOnly
    return Download

  new Download(config, callback)
