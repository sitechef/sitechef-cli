InstallModules = require '../../../lib/initialiser/installNodeModules'

rimraf = require 'rimraf'
fs = require 'fs'

describe "Install node modules", ->

  describe "E2E", ->

    themeDir = '/tmp/siteChefTempTheme-06'
    removeDemoDirectory = ->
      try
        rimraf.sync themeDir
      catch e
        "Dont care"

    beforeEach removeDemoDirectory
    afterEach removeDemoDirectory

    it "Should install dependency in package.json", (done) ->

      # create the theme directory
      fs.mkdirSync themeDir

      # copy package.json to temp theme file
      packageJSON = fs.readFileSync(
        __dirname + '/../../fixtures/package.json'
      )
      fs.writeFileSync(
        themeDir + '/package.json'
        , packageJSON
      )
      InstallModules themeDir
      , (err, res)->
        throw err if err
        expect(fs.existsSync(
          themeDir + '/node_modules/coffee-script'
        )).toBe true
        done()
      , false

