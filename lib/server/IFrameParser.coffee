###
# Iframe Parser
#
# Parses customer html
# to find widget iframes
# and render them using local templates
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

cheerio = require 'cheerio'

Template = require './Template'

deepExtend = require 'deep-extend'

###
# @param {Object} configuration: {
#                   rootDirectory: {String} root Directory of templates
#                   html: {String} un-rendered html
#                   cachedHtml: {String} sitechef-rendered html
#                   data: {Object} cached data for template
#                  }
# @param
# @param {Boolean} return the un-instantiated class (for testing)
###
module.exports = (config = {}, callback,  classOnly = false)->

  class IFrameParser

    # map of sections
    # to templates
    sections:
      maps:
        template: 'mapWidget.html'
        localRender: false
      contact:
        template: 'contactPage.html'
        localRender: true
      menu:
        template: 'foodMenu.html'
        localRender: true

    # defaults to be overriden
    # at runtime
    defaults:
      rootDirectory: process.cwd()
      data: {}
      html: ''
      cachedHtml: ''

    ###
    # @constructor
    # @param {Object} Config
    # @param {Object} cached data for template
    ###
    constructor: (config, @callback) ->

      @opts = deepExtend {}, @defaults, config

      @start()


    ###
    # Finds and stores widget element
    # If widget doesnt exist, calls back
    # original html
    # @return {Boolean} widget has been found
    ###
    findWidget: () =>
      unless @opts.html?
        @callback null, ''
        return false

      @$ = cheerio.load(@opts.html)
      @$widget = @$('.fol-drop-outer')
      # if widget not there, callback
      # original html
      unless @$widget.length
        @callback null, @opts.html
        return false

      true


    ###
    # Find and render
    # widget according to widget name
    ###
    parseWidgets: =>
      $iframe = @$widget.find('iframe')
      unless $iframe.length
        return @callback(
          new Error(
            "No nested iframe found"
          )
        )

      section = $iframe.data 'type'

      @renderTemplate section
      , (err, renderedTemplate) =>
        return @callback(err) if err

        # replace the widget html
        # with the new rendered template
        @$widget.replaceWith renderedTemplate

        # now callback output
        @callback null, @$.html()


    ###
    # Asynchronously renders the nunjucks
    # template
    # @param {String} section
    # @param {Object} data (context) for rendering
    # @param {Function} (err, result) ->
    ###
    renderTemplate: (section, cb) ->
      # check section is defined (above)
      unless section of @sections
        return cb(
          new Error("Unknown section #{section}")
        )

      unless section of @opts.data
        return cb(
          new Error("Section #{section} not found in data")
        )


      # get the template name
      # @TODO - dont render unrenderable sections
      templateName = @sections[section].template

      Template(@opts.rootDirectory) templateName
      , @opts.data[section], cb

    ###
    # Begins the search / render process
    ###
    start: ()=>
      return unless @findWidget()

      @parseWidgets()


  if classOnly
    return IFrameParser

  # return the iframe parser
  new IFrameParser(config, callback)

