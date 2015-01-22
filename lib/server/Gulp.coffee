###
# Gulp
#
# Runs Gulp in background
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###

exec = require('child_process').exec
path = require 'path'
sys = require 'sys'

###
# @param {String} full path of the theme directory
# @param {Array|Boolean} command to execute
#   N.B. folders should be an array of subfolders
#        to ensure cross-platform compatibility
# @param {Function} Callback (data) called on exit
###
module.exports = (themeDirectory, command=false, endCb) ->

  unless command
    command = ["node_modules", ".bin", "gulp"]

  cmd = command[command.length - 1].replace(/\ .*$/, '')

  fullPath = path.join.apply(@,
    [themeDirectory].concat(command)
  )

  # try and retain colours
  fullPath+= " --ansi"

  child = exec fullPath
  , cwd: themeDirectory
  , (err, stdout, stderr) ->
    if err || stderr
      console.error "#{cmd} error: ", (err || stderr)

    console.error "#{cmd} unexpectedly closed."
    , "Are you sure that #{cmd} watch is configured correctly?"
    if typeof endCb is 'function'
      endCb(err || stderr || stdout)

  writeLine = (data) ->
    sys.print "#{cmd} #{data}"
  child.stderr.on 'data', writeLine

  child.stdout.on 'data', writeLine

