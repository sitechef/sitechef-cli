saveTemplateFiles = require '../../../lib/initialiser/saveTemplateFiles'

rimraf = require 'rimraf'
fs = require 'fs'

describe "SaveTemplateFiles", ->

  describe "E2E", ->
    themeDir = '/tmp/siteChefTempTheme-01'
    removeDemoDirectory = ->
      try
        rimraf.sync themeDir
      catch e
        "Dont care"

    beforeEach removeDemoDirectory
    afterEach removeDemoDirectory

    it "Should expand the template files into  correct directory", (done) ->
      fs.mkdirSync themeDir

      saveTemplateFiles false
      , themeDir
      , (err, result) ->
        throw err if err
        expect(result)
          .toBe themeDir + '/templates'
        expect(fs.existsSync(
          themeDir + '/templates/subdir1/test2.html'
        )).toBe true
        done()
      ,
        themesHost:
          "https://sitecheftests.s3.amazonaws.com/testResponses/"
        endpoint: 'html.zip'

