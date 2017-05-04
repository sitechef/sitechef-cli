###
# Sends JSON and receives a JSON response
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###
deepExtend = require 'deep-extend'
request = require 'request'
_ = require 'lodash'
CustomerError = require '../errors/CustomerError'
PercentLogger = require './PercentLogger'

###
# @param {Object} config
#   {
#     method: 'GET'
#     url: 'http://themes.sitechef.co.uk/html'
#     apiKey: {String} api key
#     body: {String|Object}
#     json: {Boolean}
#     require200: {Boolean} throw an error
#                 if status not 200
#
#   }
# @param {Function} callback (err, jsonResponse)->
# @param {Boolean} just return the class
#
###
module.exports = (config, callback, classOnly = false) ->
  class FetchJSON
    defaults:
      method: 'GET'
      url: false
      apiKey: false
      body: false
      json: true
      require200: true
      message: ''

    constructor: (config, @callback) ->
      @opts = deepExtend {}, @defaults, config
      @fetch()

    ###
    # Performs the request
    # and sends the response
    # to the callback
    ###
    fetch: =>
      requestOpts = @buildOptions()
      r = request requestOpts
      , (err, res, body)=>
        # kill logger if logging
        if @logger
          @logger.destroy()

        return @callback(err) if err
        if res.statusCode is 403
          # if it's 403 error, stop all work
          # and exit
          error = "\n\nFATAL: API Code invalid. " +
          "Please check and try again"
          console.error(error)
          return process.exit(1)

        if res.statusCode is 504
          er = CustomerError(
            "Timed out while communicating with SiteChef API " +
            "- Check Your Connectivity (504)"
          )
          er.status = 504
          if process.env.DEBUG_MODE
            console.error(requestOpts, body)
          return @callback(err, body)

        if res.statusCode isnt 200
          er = CustomerError(
            "Failed to get/send to SiteChef server - " + res.statusCode
            )
          er.status = res.statusCode
          if process.env.DEBUG_MODE
            console.error(requestOpts, body)
          if @opts.require200
            return @callback(er, body)

        @callback null, body
      # dont measure progress
      # if get request
      return if @opts.method is 'GET'
      if @opts.body and _.isString(@opts.body)
        @logUpload(r, @opts.body.length) if @opts.body

    ###
    # Logs the progress
    # @param {Object} request
    # @param {Integer} filesize
    ###
    logUpload: (req, len) =>
      message = "Uploading " + @opts.message
      @logger = new PercentLogger(message
      ,
        request: req
        fileSize: len
      )

    ###
    # @return {Object}
    ###
    buildOptions: =>
      opts =
        method: @opts.method
        uri: @opts.url
        json: @opts.json

      if @opts.body
        opts.body = @opts.body

      opts.headers = @makeHeaders()

      opts


    makeHeaders: =>
      return {} unless @opts.apiKey
      {
        "X-Api-Auth": @opts.apiKey
        "X-Sitechef-Version": global.SITECHEF_VERSION
      }


  if classOnly
    return FetchJSON

  new FetchJSON(config, callback)
