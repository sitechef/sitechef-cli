###
# Writes out the percentage complete
# to the command line for request uploads
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###
Progress = require 'progress'
_ = require 'lodash'

class PercentLogger

  ###
  # Defaults
  ###
  defaults:
    ###
    # @var {Object} request object
    ###
    request: false
    ###
    # @var {Integer} filesize
    ###
    fileSize: 0
    ###
    # @var {Integer} poll delay (ms)
    ###
    pollDelay: 100

  ###
  # @param {String} message to appear before %
  # @param {Object} options
  ###
  constructor: (@message, config) ->
    @completed = false
    @percent = 0
    @Progress = Progress

    @opts = _.extend {}, @defaults
    _.extend @opts, config

    @launch()

  ###
  # Starts the progress bar
  ###
  launch: =>
    @bar = new @Progress( @message + ' [:bar] :percent'
      complete: '='
      width: 20
      total: 100
    )
    @logUpload @opts.request, @opts.fileSize

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
    dispatched = request.req
      .connection._bytesDispatched
    return 0 unless dispatched
    sent = parseInt(dispatched)
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
    prevPercent = @percent
    @percent = @getPercent request, fileSize
    diff = @percent - prevPercent
    return if @percent > 100

    @bar.tick(diff) if diff > 0

    return if @percent is 100

    @timeout = setTimeout =>
      @logUpload request, fileSize
    , @opts.pollDelay

  ###
  # Destroys the current instance
  ###
  destroy: =>
    clearTimeout @timeout


module.exports = PercentLogger


