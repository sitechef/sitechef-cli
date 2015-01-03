IFrameParser = require('../../../lib/server/IFrameParser')(
  {}, (->), true
)
cheerio = require 'cheerio'
fs = require 'fs'

describe "IFrameParser", ->
  parser = false

  beforeEach ->
    class ParserMock extends IFrameParser
      constructor: ->

    parser = new ParserMock()


  describe "findWidget", ->

    it "Should callback original html and " +
    "return false if no items", ()->
      parser.opts =
        html: 'original html'

      called = false
      parser.callback = (err, html)->
        throw err if err
        expect(html).toBe 'original html'
        called = true

      expect(parser.findWidget())
        .toBe false

    it "Should set widget and return true if div found", ->
      parser.opts =
        html: '<div><div class="fol-drop-outer"></div></div>'

      expect(parser.findWidget())
        .toBe true

      expect(parser.$widget.length)
        .toBe 1

  describe "parseWidgets", ->

    it "should call render template with the correct section"
    , (done) ->

      parser.callback = (err, html) ->
        throw err if err
        expect(html).toBe '<span>an item</span>rendered html'
        done()

      demoHtml = '<span>an item</span><div class="fol-drop-outer">' +
        '<iframe data-type="maps"></iframe></div>'

      parser.$ = cheerio.load demoHtml

      parser.$widget = parser.$('.fol-drop-outer')

      parser.renderTemplate = (section, cb) ->
        expect(section).toBe 'maps'
        cb null, 'rendered html'

      parser.parseWidgets()

  describe "renderTemplate", ->

    it "should render template with data correctly", (done)->

      templateRoot = fs.realpathSync(
        __dirname + '/../../fixtures'
      )
      parser.opts =
        rootDirectory: templateRoot
        data:
          test:
            data:
              name: 'testData'

      parser.sections =
        test:
          template: 'iframeTemplate.html'

      parser.renderTemplate 'test', (err, result) ->
        throw err if err
        expect(result)
          .toBe(
            "this should be testData and " +
            'this {"name":"testData"} encoded\n'
          )
        done()




