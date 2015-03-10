S3Upload = require(
  '../../../lib/utilities/S3Upload'
)
nock = require 'nock'
fs = require 'fs'
_ = require 'lodash'

describe "S3Upload", ->

  s3 = false

  examplePolicy =
    key: 'test-key'
    AWSAccessKeyId: 'awskey'
    policy: 'policy'
    signature: 'signature'
    "Content-Type": "contenttype"
    bucket: 'test'
    gzip: false

  beforeEach ->

    class Mock extends S3Upload
      constructor: ->

    s3 = new Mock()

  describe "getFileSize", ->

    it "Should return the file size of a file", (done) ->
      s3.filePath = __dirname + '/../../fixtures/' +
        'scss/demo.scss'

      s3.getFileSize (err, res) ->
        throw err if err
        expect(res).toBe 27
        done()

  describe "makeOptions", ->

    it "Should generate the correct options list", ->

      s3.policy = examplePolicy
      s3.acl = 'public-read'

      s3.filePath = __dirname + '/../../fixtures/' +
        'scss/demo.scss'

      res = s3.makeOptions(29)
      expect(res.method).toBe 'POST'
      expect(res.url).toBe(
        "https://test.s3.amazonaws.com/"
      )

      opts = res.formData

      expect(opts.file.readable).toBe true

      expect(opts.key).toBe 'test-key'
      expect(opts.AWSAccessKeyId).toBe 'awskey'
      expect(opts.acl).toBe 'public-read'
      expect(opts.policy).toBe 'policy'
      expect(opts.signature).toBe 'signature'
      expect(opts['Content-Type']).toBe 'contenttype'
      expect(opts['Content-Length']).toBe 29

    it "Should add content encoding if gzip specified", ->
      s3.policy = _.clone examplePolicy
      s3.policy.gzip = true
      s3.acl = 'public-read'

      s3.filePath = __dirname + '/../../fixtures/' +
        'test.js.gz'

      res = s3.makeOptions(59)
      expect(res.formData['Content-Encoding'])
        .toBe 'gzip'

  describe "e2e", ->

    fixtures = __dirname + '/../../fixtures/'
    beforeEach ->
      s3.policy = examplePolicy
      s3.filePath = fixtures +
        'scss/demo.scss'

      s3.acl = 'public-read'
      s3.log = ->
      s3.logUpload = (r, size) ->
        expect(size).toBe 27

    it "Should upload file to S3", (done)->


      nock('https://test.s3.amazonaws.com')
        .post('/')
        .reply 200, (url, body) ->
          testBody = body.replace /^\-.*/gm, ''
          path = fixtures + 'expectedUploadBody.txt'
          expectedBody = fs.readFileSync(path).toString()
          expect(testBody)
            .toBe expectedBody

          return 'ok'

      s3.callback = (err, res) ->
        throw err if err
        done()

      s3.start()

    it "Should retry twice if first upload fails", (done)->
      nock('https://test.s3.amazonaws.com')
        .post('/')
        .reply(403, (url, body) ->
          return 'fail'
        )
      nock('https://test.s3.amazonaws.com')
        .post('/')
        .reply(200, (url, body) ->
          return 'pass'
        )


      s3.retried = 0

      s3.callback = (err, res) ->
        expect(s3.retried).toBeGreaterThan 0
        done()

      s3.start()



