UploadDist = require(
  "../../../lib/publisher/UploadDist"
)(null,null,null, true)

nock = require 'nock'
fs = require 'fs'

describe "UploadDist", ->

  uploadDist = false

  beforeEach ->
    class Mock extends UploadDist
      constructor: ->

    uploadDist = new Mock()

  describe "getFileList", ->
    it "should return all files in subdirectories of dist", (done)->
      fixtures = __dirname + '/../../fixtures'
      uploadDist.themeRoot = fixtures

      uploadDist.getFileList (err, files) ->
        throw err if err
        expect(files.length)
          .toBe 3
        done()


  describe "addMime", ->

    it "Should add correct mime format to file", (done)->

      files =[
        'test.txt'
        'text.jpg'
      ]
      uploadDist.addMime files
      , (err, files)->
        expect(files.length).toBe 2

        expect(files[0].contentType)
          .toBe 'text/plain'
        expect(files[1].contentType)
          .toBe 'image/jpeg'
        expect(files[0].path).toBe 'test.txt'
        done()

  describe "getPolicies", ->

    it "Should make a POST request to " +
      " https://themes.sitechef.co.uk/dist with paths"
    , (done)->

      nock('https://themes.sitechef.co.uk',{
        "X-Api-Auth":"apiCode"
      }).post('/dist')
        .reply 200, (url, body) ->
          data = JSON.parse(body)
          expect(data.files.length)
            .toBe 2
          expect(data.files[0].contentType)
            .toBe 'image/jpeg'
          return JSON.stringify(
            ['item1']
          )

      uploadDist.apiKey = 'apiCode'
      uploadDist.getPolicies [
        {
          path: 'test.jpg'
          contentType: 'image/jpeg'
        }
        {
          path: 'test.txt'
          contentType: 'text/plain'
        }
      ], (err, result) ->
        throw err if err
        expect(result[0]).toBe 'item1'
        done()

  describe "uploadFile", ->

    it "Should create the correct local path", (done)->

      class S3Test
        constructor: (path, policy, cb) ->
          expect(path).toBe(
            __dirname + '/dist/item.txt'
          )
          expect(policy.policy).toBe 'policy'
          cb(null, true)

      uploadDist.S3Upload = S3Test
      uploadDist.themeRoot = __dirname

      uploadDist.uploadFile
        policy: 'policy'
        localPath: 'item.txt'
        gzip: false
      , (err, res) ->
        throw err if err
        done()

    it "Should gzip encode javascript files", (done)->
      tempPath = false
      class S3Test
        constructor: (path, policy, cb) ->
          tempPath = path
          size = fs.statSync(path).size
          expect(size).toBe 57
          cb(null, true)

      uploadDist.S3Upload = S3Test
      uploadDist.themeRoot = __dirname + '/../../fixtures'

      uploadDist.uploadFile
        policy: 'policy'
        gzip: true
        localPath: 'test.js'
      , (err, res) ->
        exists = true
        try
          fs.accessSync(tempPath)
        catch e
          exists = false

        throw err if err
        expect(tempPath)
          .not.toBe false
        expect(exists)
          .toBe false
        done()

