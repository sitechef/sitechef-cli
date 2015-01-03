###
# CLI Utility
#
# Handles Command Line Interactions
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###
fs = require 'fs'
Init = require './initialiser'
Server = require('./server')()
Publisher = require('./publisher')()

module.exports = (overrides) ->
  packageData = JSON.parse(
    fs.readFileSync(__dirname + '/../package.json')
  )
  instructions = [
    "SiteChef Command Line Utility Version " + packageData.version
    ""
    "Usage:"
    ""
    "  sitechef init <apikey> [<directory name>]"
    ""
    "       Downloads all the theme information from the server"
    "       using the ApiKey generated at admin.sitechef.co.uk"
    "       If no directory name specified it will generate "
    "       from the theme name"
    ""
    "  sitechef serve [<port>]"
    ""
    "       Serves the template at http://localhost:3999/ "
    "       unless a port is specified"
    ""
    "  sitechef publish"
    "       "
    "       Publishes your theme back to SiteChef"
    ""
    ""
  ]

  complete = [
    ""
    "Your theme is now successfully installed"
    "Change to your directory and execute 'sitechef serve'"
    "to preview your theme locally"
    ""
  ]

  argv = require('minimist')(process.argv.slice(2))

  sendInstructions = ->
    console.log(instructions.join('\n'))
    process.exit()

  sendInstructions() unless argv._.length

  action = argv._[0]
  cwd = process.cwd()

  switch action

    when "init"
      unless argv._.length > 1
        return sendInstructions()
      apiKey = argv._[1]
      directoryOverride = false
      if argv._.length > 2
        directoryOverride = argv._[2]

      console.log instructions[0]
      console.log "\n\nGenerating Theme ....\n\n"
      , "...this may take a minute or two...\n\n"
      Init
        themeDirectory: cwd
        themeOverride: directoryOverride
        apiKey: apiKey
      , (err, results) ->
        if err
          if 'code' of err and err.code is 'EEXIST'
            return console.error "\n\nINSTALLATION FAILED\n\n"
            , "Directory Already Exists\n\n\n"
          console.error("\n\nINSTALLATION FAILED \n\n"
          , " If this happens again, report to dev@sitechef.co.uk \n\n"
          , " Details: "
          , err, err.stack.split("\n")
          )
          return process.exit()
        console.log "Installed to "
        , results.generateFolder.path
        console.log complete.join('\n')
        process.exit()

    when 'serve'
      port = null
      if argv._.length > 1
        port = argv._[1]

      server = new Server cwd, port

    when 'publish'
      console.log "\n\nPublishing Theme...\n\n"
      publish = new Publisher cwd

    else
      sendInstructions()
