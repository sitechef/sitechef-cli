###
# Defaults for interacting with the theme api
#
# Generates object with themesHost and endpoint as keys
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

###
# @param {String|Boolean} section
# @param {Object|Null} overrides for keys
###
module.exports = (section, overrides) ->
  defaults =
    themesHost: 'https://themes.sitechef.co.uk/'
    endpoints:
      srcZip: 'srczip'
      dataFile: 'datafile'
      themeMeta: 'theme'
      htmlZip: 'html.zip'
      html: 'html'

  if process.env.LOCAL_SERVER
    defaults.themesHost = process.env.LOCAL_SERVER

  if section and not section of defaults.endpoints
    throw new Error("Section #{section} not found")

  out =
    themesHost: defaults.themesHost


  if section
    out.endpoint = defaults.endpoints[section]

  deepExtend(out, overrides) if overrides?

  out
