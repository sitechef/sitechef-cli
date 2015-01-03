saveThemeMeta = require '../../../lib/initialiser/saveThemeMeta'

rimraf = require 'rimraf'
fs = require 'fs'

describe "SaveThemeMeta", ->

  describe "E2E", ->

    themeDir = '/tmp/siteChefTempTheme-03'
    removeDemoDirectory = ->
      try
        rimraf.sync themeDir
      catch e
        "Dont care"

    beforeEach removeDemoDirectory
    afterEach removeDemoDirectory

    it "should download, store and format theme.json"
    , (done) ->

      fs.mkdirSync themeDir
      themeDest = themeDir + '/theme.json'
      saveThemeMeta
        meta:
          name: 'Test Site'
      , themeDir
      , (err, result) ->
        throw err if err
        expect(result).toBe themeDest

        data = JSON.parse(fs.readFileSync(themeDest))
        expect(data.meta.name)
          .toBe 'Test Site'
        done()
