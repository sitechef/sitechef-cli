###
# Template Processor
#
# Renders a nunjucks template
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

nunjucks = require 'nunjucks'
NunjucksEnv = require './NunjucksEnv'


module.exports = (rootDirectory)->

  env = NunjucksEnv.make(nunjucks, rootDirectory)

  render = (template, data, callback) ->
    try
      env.render template, data, callback
    catch e
      errorMessage = "<h1>Error Rendering Templates</h1>"
      errorMessage+= "<h4>#{e.message}</h4>"
      errorMessage+= e.stack.replace("\n", "<br/>")
      callback null, errorMessage
