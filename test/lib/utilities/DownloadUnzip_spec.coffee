rimraf = require 'rimraf'
fs = require 'fs'
DownloadUnzip = require(
  '../../../lib/utilities/DownloadUnzip'
)({}, {}, true)
fs = require 'fs'

describe "DownloadUnzip", ->

  downloadMock = false

  beforeEach ->
    class DownloadMock extends DownloadUnzip
      constructor: ->

    downloadMock = new DownloadMock()


  describe "getTempPath", ->

    it "Should generate a unique zip file path", ->

      version1 = downloadMock.getTempPath()
      version2 = downloadMock.getTempPath()
      expect(version1)
        .not.toBe(version2)

      expect(version1)
        .toMatch /tmp.*stcf.*\.zip/

  describe "writeProgress", ->

    it "Should use description if available", (done) ->

      downloadMock.log = (message) ->
        expect(message)
          .toBe 'Description [100%]'
        done()

      downloadMock.opts =
        description: 'Description'

      downloadMock.writeProgress percent:100

  describe "e2e", ->

    removeTestDir = ->
      try
        rimraf.sync '/tmp/siteChefCliTest'
      catch e
        "dont care"

    beforeEach removeTestDir
    afterEach removeTestDir

    it "Should download and expand a zip folder", (done)->
      downloadMock.log = (message) ->

      downloadMock.opts =
        description: "Description"
        destination: "/tmp/siteChefCliTest"
        src: "https://sitecheftests.s3.amazonaws.com/testResponses/html.zip"
        apiKey: false
        zipSaveLocation: false

      downloadMock.callback = (err, dir) ->
        throw err if err
        expect(dir)
          .toBe '/tmp/siteChefCliTest'
        expect(fs.existsSync('/tmp/siteChefCliTest/test1.html'))
          .toBe true
        expect(fs.existsSync('/tmp/siteChefCliTest/subdir1/test2.html'))
          .toBe true
        done()

      downloadMock.start()

    it "Should gracefully handle 403", (done)->

      downloadMock.log = ->
      downloadMock.opts =
        description: "Description"
        destination: "/tmp/siteChefCliTest"
        src: "https://sitecheftests.s3.amazonaws.com/doesntExist.zip"
        apiKey: false
        zipSaveLocation: false

      downloadMock.callback = (err, dir) ->
        expect(err.message)
          .toBe(
            'Failed to download file ' +
            '(https://sitecheftests.s3.' +
            'amazonaws.com/doesntExist.zip): Status 403'
          )
        done()

      downloadMock.start()

