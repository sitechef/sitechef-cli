UploadTemplateFiles = require(
  '../../../lib/publisher/UploadTemplateFiles'
)(null,null,null, true)

nock = require 'nock'

describe "UploadTemplateFiles", ->

  uploadFile = false

  beforeEach ->
    class Mock extends UploadTemplateFiles
      constructor: ->
    uploadFile = new Mock()

  describe "beforeStart", ->
    it "Should send a delete request to " +
    "https://themes.sitechef.co.uk/html"
    , (done) ->

      nock('https://themes.sitechef.co.uk'
        ,
          'X-Api-Auth': 'apiCode'
      ).delete('/html')
        .reply 200, {success: true}

      uploadFile.apiKey = 'apiCode'

      uploadFile.beforeStart (err, res) ->
        expect(err).toBe null
        done()


