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
Updater = require './updater'
Setup = require './setup'

module.exports = (overrides) ->
  packageData = JSON.parse(
    fs.readFileSync(__dirname + '/../package.json')
  )
  # add the version to the global
  # instance so it can be used in requests
  global.SITECHEF_VERSION = packageData.version

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
    "  sitechef setup <apikey>"
    ""
    "       Writes the sitechef config file and downloads the latest json"
    "       snapshot writing data to the current directory."
    "       Used when setting up a cloned git repo."
    ""
    "  sitechef serve [-p <port>] [-e <development|production>"
    ""
    "       Serves the template at http://localhost:3999/ "
    "       -p specify override port eg 9000  "
    "       -e override environment for templating eg production "
    ""
    "  sitechef publish"
    "       "
    "       Publishes your theme back to SiteChef"
    ""
    "  sitechef update"
    ""
    "       Updates your local data file from the latest"
    "       data on the website."
    "       N.B. Remember to run 'Generate JSON Snapshot' first"
    "            (found in the Theme Manager at admin.sitechef.co.uk)"
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

    when "setup"
      unless argv._.length > 1
        return sendInstructions()
      apiKey = argv._[1]

      console.log instructions[0]

      console.log "\n\nWriting core sitechef files ...\n\n"

      Setup cwd, apiKey



    when 'serve'
      port = null
      environment = null
      port = argv.p if argv.p
      environment = argv.e if argv.e

      server = new Server cwd, port, environment

    when 'publish'
      console.log "\n\nPublishing Theme...\n\n"
      publish = new Publisher cwd

    when 'update-data', 'data-update', 'update'
      console.log "\n\nFetching the latest data file...\n\n"
      Updater(cwd)

    else
      sendInstructions()
