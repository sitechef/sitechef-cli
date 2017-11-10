###
# Serves Theme Locally using Express
#
# Loads & parses data.json, creates Express
# server and runs Gulp watch in background
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###
express = require 'express'
_ = require 'lodash'
path = require 'path'
async = require 'async'
request = require 'request'
requestProxy = require 'express-request-proxy'
MobileDetect = require 'mobile-detect'
fs = require 'fs'

Template = require './Template'
Gulp = require './Gulp'

module.exports = ->

  class Server

    ###
    # @constructor
    # @param {String|Boolean} absolute path of theme directory
    # @param {Integer} express port number
    # @param {String} environment
    ###
    constructor: (
      @themeRoot = false,
      @port = 3999,
      @environment= 'development',
      @forwarding= false,
    ) ->

      unless @themeRoot
        @themeRoot = @_getCWD()

      @readSiteChefRC()
      @loadDataFile()
      @loadCustomDataFile()
      @filterPagesById()
      @runGulp()
      @generateApp()
      @serve()

    ###
    # Reads the .sitechefrc file
    # if it exits
    ###
    readSiteChefRC: =>
      rcPath = path.join @themeRoot, '.sitechefrc'
      try
        @rcContents = JSON.parse(
          fs.readFileSync(rcPath)
        )
      catch e
        @rcContents = {}

    ###
    # Loads The JSON data file
    # from the theme directory
    ###
    loadDataFile: =>
      dataFilePath = path.join @themeRoot
      , '.sitechef', 'data.json'
      try
        @data = JSON.parse(
          fs.readFileSync(dataFilePath)
        )
      catch e
        console.error(
          "Could not read data file. Try downloading again"
        )
        # exit now
        process.exit(1)

    ###
    # Loads custom data file
    # if it exists
    #
    # Format of `sitechefMockAPI.json`:
    # {
    #   "GET=/route-override": { // ie <METHOD>=<uri>
    #     "templateName": "myTemplate.html",
    #     "status": 200, // optional
    #     "merge": true, // if false, data below is only response
    #     "data": {
    #       "item1": "item2"
    #     }
    #   }
    # }
    ###
    loadCustomDataFile: =>
      dataFilePath = path.join @themeRoot
      , 'sitechefMockAPI.json'
      try
        fileContents = fs.readFileSync(dataFilePath)
      catch e
        # file not found / not readable
        # so set customData empty
        @customData = {}
        return

      try
        @customData = JSON.parse(fileContents)
      catch e
        console.error(
          "Failed to parse JSON of your custom data file"
        )
        process.exit(1)

    ###
    # Filters pages by id
    # so they can be easily returned
    # by the nunjucks get_page function
    ###
    filterPagesById: =>
      filteredPages = _.filter(@data
      , (data, section) ->
        # ignore any items
        # that begin with '/api'
        !(
          section.match(/^.api/) or
          section.match(/p\/\d+(\.json)?$/)
        )
      )
      @pagesById = _.reduce(filteredPages
      , (memo, val) ->
        return memo unless val.content
        memo[val.content.id] = val.content
        memo
      , {})

    ###
    # Executes Gulp in the background
    # in order to recompile assets on the fly
    ###
    runGulp: =>
      compilerCmd = false
      if 'compileCommand' of @rcContents
        compilerCmd = @rcContents.compileCommand

      return unless compilerCmd

      Gulp @themeRoot, compilerCmd
      , (data) ->
        # data already printed
        # by gulp
        # so just crash process
        process.exit(1)

    ###
    # Creates the express app
    ###
    generateApp: =>
      @appRoot = @_getCWD()
      @app = express()
      # add in static routes

      # main dist/ routes
      @app.use '/assets/dist'
      , express.static(path.join(@themeRoot, 'dist'))

      # tmp route for local files
      @app.use '/tmp'
      , express.static(path.join(@themeRoot, 'tmp'))

      # instantiate render command
      @render = Template(path.join(@themeRoot, 'templates'))

      @app.all('*', @respond)

      if @forwarding
        console.log("Forwarding unhandled requests to #{@forwarding}")
        @app.all('/*', requestProxy(
          url: "#{@forwarding}/*"
          timeout: 30 * 1000,
        ))
      @app.use @handleErrors
      @app

    ###
    # Responds to all routes
    ###
    respond : (req, res, next) =>

      {data, templateName, status} = @getData(req)

      return next() unless data

      # if it's an xhttprequest
      # return json format
      if req.xhr or (req.headers.accept.indexOf('json') > -1)
        return res
          .status(status)
          .json(data)

      # function for getting
      # page
      data.get_page = (id) =>
        return false unless id?
        return false unless @pagesById[id]?
        @pagesById[id]

      @render templateName, data, (err, result) ->
        return next(err) if err

        res.status(status).send result

    cleanUrl: (req) =>
      lowercaseUrl = req.url.toLowerCase()
        .replace /([a-zA-Z])\/$/, '$1'

      if lowercaseUrl of @data
        return lowercaseUrl

      return req.url

    getData: (req) =>
      url = @cleanUrl(req)

      customData = @getCustomData(req)

      if customData
        coreData = if @data[url] then @data[url] else @data['/']
      else
        coreData = @data[url]

      if not coreData and not customData
        return {}

      coreData.environment = @environment

      if customData and customData.merge is false
        data = customData.data
      else
        data = _.merge {}
        , coreData
        , if customData
        then customData.data
        else {}

      status = if customData then customData.status or 200
      else 200

      templateName = @getTemplateName req, customData

      {
        data,
        status,
        templateName,
      }


    getCustomData: (req) =>
      if req.url is "/_coming_soon"
        return {
          templateName: 'comingSoon.html'
          data: {}
        }

      mockString = "#{req.method}=#{req.url}"

      return false unless mockString of @customData

      @customData[mockString]

    getTemplateName: (req, customData) =>
      return 'index.html' unless customData

      customData.templateName

    ###
    # Checks if accessed
    # using mobile useragent
    # and updates page data
    # @param {Object} Express request
    # @param {Object} page data
    # @return {Object} page data
    ###
    mobileCheck: (req, data) =>
      # check useragent string
      md = new MobileDetect(req.headers['user-agent'])
      return data unless md.mobile()
      # now update every "isMobile" key to true
      @updateIsMobile(data, true)

    ###
    # Recursively searches
    # objects and arrays
    # for any item with key 'isMobile'
    # and sets to true
    # @param {Object|Array} data
    # @param {Boolean} value to set 'isMobile' key
    # @return {Object|Array} data
    ###
    updateIsMobile: (data, isMobile = true) =>
      return data unless typeof data is 'object'
      _.transform data, (result, val, key) =>
        # recurse if this is an object / array
        if _.isObject(val) or _.isArray(val)
          result[key] = @updateIsMobile(val, isMobile)
          return true
        # if this is the 'isMobile' key, set to
        # desired value
        if key is 'isMobile'
          result[key] = isMobile
          return true
        # return whatever else already existed here
        result[key] = val
        true

    ###
    # Deal with http errors
    ###
    handleErrors: (err, req, res, next) ->
      unless err
        return next()

      res.status(500)
        .send(
          "<h1>Error</h1><h2>#{err.message}</h2>" +
          err.stack.split('<br/>')
        )

    ###
    # Start the server on correct port
    ###
    serve: =>
      @server = @app.listen @port
      , (err) =>
        throw err if err
        console.log "Serving SiteChef theme on port #{@port}"
        console.log "View at http://localhost:#{@port}/ "

    ###
    # @return string current working directory
    ###
    _getCWD: ->
      process.cwd()


  Server
