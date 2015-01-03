nock = require 'nock'
FindAndUpload = require('../../../lib/utilities/FindAndUpload')
describe "FindAndUpload", ->

  findAndUpload = false

  beforeEach ->
    class UploadMock extends FindAndUpload
      constructor: ->

    findAndUpload = new UploadMock()

  describe "findFiles", ->

    it "should find all files matching glob pattern", (done)->

      findAndUpload.directoryRoot = __dirname +
        '/../../fixtures/scss'

      findAndUpload.findFiles (err, files) ->
        expect(files.length).toBe 2
        expect(files[1]).toBe(
          'otherFolder/otherFile.sass'
        )
        done()

  describe "uploadFiles", ->
    it "Should log each file upload", (done)->
      spyOn findAndUpload, 'log'

      findAndUpload.uploadFile = (file, cb) ->
        cb null, file

      findAndUpload.uploadFiles [
        "firstFile.scss"
        "secondFile.scss"
      ]
      , (err, result) ->
        expect(findAndUpload.log)
          .toHaveBeenCalled()
        expect(findAndUpload.log.calls.count())
          .toBe 2
        done()


  describe "uploadFile", ->

    it "should call readfile with filepath then sendFile", (done)->
      findAndUpload.readFile = (file, cb) ->
        expect(file).toBe 'testFile.scss'
        cb null, 'contents'

      findAndUpload.sendFile = (file, body, cb) ->
        expect(body).toBe 'contents'
        cb null, true

      findAndUpload.uploadFile 'testFile.scss'
      , (err, res) ->
        expect(res).toBe true
        done()

  describe "readFile", ->

    it "Should generate path correctly and read file", (done) ->
      findAndUpload.directoryRoot = __dirname +
      '/../../fixtures/scss'

      findAndUpload.readFile 'otherFolder/otherFile.sass'
      , (err, contents) ->
        expect(contents.toString()).toBe "Demo2\n"
        done()

  describe "sendFile", ->

    it "Should send the raw body as in a PUT request" +
      " to https://themes.sitechef.co.uk"
    , (done) ->
      nock("https://themes.sitechef.co.uk"
        , "X-Api-Auth": "apicode"
      ).put('/scss/file/name.scss')
        .reply 200
        , (uri, body) ->
          expect(body)
            .toBe 'Example Body'

          return JSON.stringify(
            success: true
          )

      findAndUpload.apiKey = 'apicode'

      findAndUpload.sendFile 'file/name.scss'
      , 'Example Body'
      , (err, result) ->
        throw err if err
        done()


