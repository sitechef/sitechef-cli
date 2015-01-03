###
# Error with a message that can
# be nicely formatted for customer
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###
module.exports = (message) ->
  error = new Error(message)
  error.name = "CustomerError"
  error
