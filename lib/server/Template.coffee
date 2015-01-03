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
    env.render template, data, callback
