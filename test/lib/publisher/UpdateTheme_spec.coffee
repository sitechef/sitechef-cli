UpdateTheme = require(
  '../../../lib/publisher/UpdateTheme'
)({}, 'none', (->), true)

nock = require 'nock'

describe "UpdateTheme", ->

  updateTheme = false

  beforeEach ->
    class UpdateThemeMock extends UpdateTheme
      constructor: ->

    updateTheme = new UpdateThemeMock()

  describe "start", ->

    it "should call readJSONFile and saveThemeData", (done)->

      called = 0
      updateTheme.readJSONFile = (cb)->
        called++
        cb null, 'test'

      updateTheme.saveThemeData = (data, cb) ->
        called++
        cb null, data

      updateTheme.callback = (err, data) ->
        expect(data).toBe 'test'
        expect(called).toBe 2
        done()

      updateTheme.start()

  describe "readJSONFile", ->

    it "Should read the json file and parse it's contents", (done)->

      fixtures = __dirname +
      '/../../fixtures/'

      updateTheme.themeRoot = fixtures

      updateTheme.readJSONFile (err, data) ->
        expect(data.meta.name)
          .toBe 'Test Site'

        done()

  describe "saveThemeData", ->

    it "Should send a put request to themes", (done)->
      nock('https://themes.sitechef.co.uk'
        ,
          'X-Api-Auth':'apicode'
      ).put('/theme')
        .reply 200
        , (uri, body) ->
          data = JSON.parse(body)
          expect(data.meta.name)
            .toBe 'Test Site'

          return JSON.stringify(
            success: true
          )
      updateTheme.apiKey = 'apicode'
      updateTheme.saveThemeData
        meta:
          name: 'Test Site'
      , (err, res) ->
        throw err if err
        expect(res.success).toBe true
        done()
