UploadZip = require('../../../lib/publisher/UploadZip')(
  null
  null
  null
  null
  true
)
nock = require 'nock'
rimraf = require 'rimraf'
AdmZip = require 'adm-zip'
fs = require 'fs'

describe "UploadZip", ->

  upload = false
  beforeEach ->
    class Mock extends UploadZip
      constructor: ->

    upload = new Mock()

  describe "setupIgnore", ->
    it "should set up ignore files correctly", ->
      result = upload.setupIgnore [
        "testDir*"
        "anotherDirectory"
      ]
      expect(result.length).toBe(7)
      matches = "/home/myDir/testDirectory2/file".match(result[0])
      expect(matches.length)
        .toBeGreaterThan 0

      matches2 = "/home/myDir/wrongDirectory/fes".match(result[0])
      expect(matches2)
        .toBe null

      matches3 = "/demo/anotherDirectory/myFile".match(result[1])
      expect(matches3.length)
        .toBeGreaterThan 0

      matches4 = "/demo/anotherDirectory2/myFile".match(result[1])
      expect(matches4)
        .toBe null

  describe "Start", ->

    it "should call cleanup if one fails", (done) ->
      func = (cb) ->
        cb()
      upload.getPolicy = upload.uploadToS3 = upload.cleanup = func

      upload.buildZip = (cb) ->
        cb('error')

      spyOn(upload, 'cleanup')
        .and.callThrough()

      upload.callback = (err, res) ->
        expect(err).toBe 'error'
        expect(upload.cleanup).toHaveBeenCalled()
        expect(upload.cleanup.calls.count()).toBe 1
        done()

      upload.start()

  describe "buildZip", ->
    tmpPath = '/tmp/sitechefTemp-01'
    removeTempDir =  ->
      try
        rimraf.sync(tmpPath)
      catch e
        "dontcare"

    beforeEach removeTempDir
    afterEach removeTempDir

    it "should zip up files using ignore pattern", (done)->
      upload.setupIgnore ['ignoreFolder']
      upload.themeRoot = fs.realpathSync(
        __dirname + '/../../fixtures/demoDir'
      )
      upload.buildZip (err, stream) ->
        throw err if err

        path = stream.path
        # try unzipping this file
        # to a temp dir
        z = new AdmZip(path)
        z.extractAllTo(tmpPath)
        # now check that correct files exist
        expect(
          fs.existsSync(tmpPath + '/testFile1')
        ).toBe true
        expect(
          fs.existsSync(tmpPath + '/correctDir/subdir/file2')
        ).toBe true
        expect(
          fs.existsSync(tmpPath + '/ignoreFolder/ignorefile')
        ).toBe false
        expect(
          fs.existsSync(tmpPath + '/.gitignore')
        ).toBe true
        done()


  describe "getPolicy", ->

    it "Should send a PUT request to " +
      "https://themes.sitechef.co.uk/srczip", (done) ->
        nock("https://themes.sitechef.co.uk"
          , "X-Api-Auth": 'apiCode'
        )
          .put("/srczip")
          .reply 200, "ok"
        upload.apiKey = 'apiCode'
        upload.getPolicy (err, result) ->
          throw err if err
          expect(result).toBe 'ok'
          done()

  describe "UploadToS3", ->

    it "Should call S3 upload with correct params", (done)->
      class S3Mock
        constructor: (path, policy, cb, acl) ->
          expect(path).toBe 'path'
          expect(policy).toBe 'policy'
          expect(acl).toBe 'private'
          done()

      upload.S3Upload = S3Mock
      upload.uploadToS3 'policy', {path:'path'}, (->)


  describe "filterFile", ->

    it "Should return true when file path " +
    "does not match ignore expressions", ->

      upload.setupIgnore [
        "testDir*"
      ]
      expect(upload.filterFile("/oneDir/twoDir/file.scss"))
        .toBe true

    it "Should return false when file path" +
    " matches ignore file", ->

      upload.setupIgnore ["testDir*"]

      expect(upload.filterFile("/oneDir/second/testDir3/a"))
        .toBe false

