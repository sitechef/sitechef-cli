###
# Nunjucks Environment Generator
#
# adds a series of common filters
# to the nunjucks environment
#
# @license SiteChef grants you the right to use, modify and distribute
#          the following code so long as it is used on a website hosted
#          by the SiteChef platform and administered via sitechef.co.uk
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###
moment = require 'moment'

class NunjucksEnv

  ###
  # Generates a nunjucks
  # environment
  # @param {Nunjucks} instance of nunjucks
  # @return {NunjucksEnvironment}
  ###
  make: (nunjucks, rootPath) =>
    env = nunjucks.configure rootPath
    ,
      autoescape: true
    for name, filter of @filters
      env.addFilter name, filter
    env

  ###
  # List of filters
  # Included by default
  ###
  filters:
    ###
    # Creates a random number
    # between 0 and val
    ###
    rnd: (val) ->
      return val unless val?
      parseInt(Math.random() * val)

    ###
    # Changes line breaks to <br>
    ###
    nl2br: (val) ->
      return val unless val?
      return val unless typeof val is 'string'
      val.replace /\n/g, '<br>'

    ###
    # Returns an item json encoded
    # and escaped of html backslashes
    ###
    json_encode: (val) ->
      JSON.stringify(val)
        .replace(/\//g, '\\/')

    ###
    # Strips Tags from input string
    ###
    striptags: (val) ->
      return val unless typeof val is 'string'
      val.replace /\<[^\>]+\>/g, ''

    ###
    # Formats a date
    ###
    format_date: (val, format, inputFormat = "YYYY-MM-DD HH:mm:ss") ->
      return val unless typeof val is 'string'
      m = new moment(val, inputFormat)
      console.log m
      m.format(format)

  ###
  # Extends this class
  # with a series of items
  #
  # @param {Object} new filter functions
  ###
  extend: (obj) =>
    unless typeof obj is 'object'
      throw new Error("Only takes objects")
    for key, func in obj
      @filters[key] = func

module.exports = new NunjucksEnv()
