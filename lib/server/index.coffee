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
fs = require 'fs'

IFrameParser = require './IFrameParser'
Template = require './Template'
Gulp = require './Gulp'

module.exports = ->

  class Server

    ###
    # @constructor
    # @param {String|Boolean} absolute path of theme directory
    # @param {Integer} express port number
    ###
    constructor: (@themeRoot = false, @port = 3999) ->

      unless @themeRoot
        @themeRoot = @_getCWD()

      @loadDataFile()
      @runGulp()
      @generateApp()
      @serve()


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
    # Executes Gulp in the background
    # in order to recompile assets on the fly
    ###
    runGulp: =>
      Gulp @themeRoot, false
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
      @app.use @handleErrors
      @app

    ###
    # Responds to all routes
    ###
    respond : (req, res, next) =>
      url = req.url.toLowerCase()
        .replace /([a-zA-Z])\/$/, '$1'

      return next() unless url of @data

      pageData = @data[url]

      # if it's an xhttprequest
      # return json format
      if req.xhr
        unless 'widgets' of pageData
          return res.json pageData
        pData =
          content: pageData
        return @renderIframes(pData
        , (err, data) ->
          return next(err) if err
          res.json data.content
        )

      async.waterfall [
        ((cb) =>
          @renderIframes pageData, cb
        )
        ((data, cb) =>
          @render 'index.html', data, cb
        )
      ], (err, result) ->
        return next(err) if err

        res.send result

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
    # Parse and render local iframes
    # if exist
    # @param {Object} render variables
    # @param {Function} callback (err, pageData)
    ###
    renderIframes: (data, cb) =>
      return cb(null, data) unless 'content' of data
      return cb(null, data) unless 'widgets' of data.content
      parser = IFrameParser
        rootDirectory: path.join(@themeRoot, 'templates')
        data: data.content.widgets
        html: data.content.rawBody
        cachedHtml: data.content.body
      , (err, renderedHtml) ->
        return cb(err) if err
        data.content.body = renderedHtml
        cb null, data


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
