saveSnapshotFile = require '../../../lib/initialiser/saveSnapshotFile'

rimraf = require 'rimraf'
fs = require 'fs'
exists = require '../../helpers/exists'

describe "saveSnapshotFile", ->

  describe "E2E", ->

    themeDir = '/tmp/siteChefTempTheme-04'
    removeDemoDirectory = ->
      try
        rimraf.sync themeDir
      catch e
        "Dont care"

    beforeEach removeDemoDirectory
    afterEach removeDemoDirectory

    it "should download and store data.json"
    , (done) ->

      fs.mkdirSync themeDir
      fs.mkdirSync themeDir + '/.sitechef'
      themeDest = themeDir + '/.sitechef/data.json'
      saveSnapshotFile false
      , themeDest
      , themeDir
      , (err, result) ->
        throw err if err
        expect(result).toBe themeDest

        expect(exists(themeDest))
          .toBe true
        expect(exists(themeDir + '/prefs.scss'))
          .toBe true

        done()
      ,
        themesHost:
          'https://sitecheftests.s3.amazonaws.com/testResponses/'
        endpoint: 'datafile.json'

