expandSrcZip = require '../../../lib/initialiser/expandSrcZip'

rimraf = require 'rimraf'
fs = require 'fs'

describe "ExpandSrcZip", ->

  describe "E2E", ->

    themeDir = '/tmp/siteChefTempTheme-02'
    removeDemoDirectory = ->
      try
        rimraf.sync themeDir
      catch e
        "Dont care"

    beforeEach removeDemoDirectory
    afterEach removeDemoDirectory

    it "Should download and unzip src.zip using signed url"
    , (done) ->

      fs.mkdirSync themeDir
      fs.mkdirSync themeDir + '/.sitechef'

      # write a test
      # file to ensure not overwritten
      # in expansion
      fs.writeFileSync themeDir + 'example.js', 'test'

      zipDest = themeDir + '/.sitechef/src.zip'
      expandSrcZip false
      , themeDir
      , zipDest
      , (err, result) ->
        throw err if err
        expect(result).toBe themeDir

        expect(fs.existsSync(zipDest))
          .toBe true

        expect(fs.existsSync(themeDir + 'example.js'))
          .toBe true

        done()
      ,
        themesHost:
          'https://sitecheftests.s3.amazonaws.com/testResponses/'
        endpoint: 'srczip.json'

