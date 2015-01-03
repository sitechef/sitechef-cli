Publisher = require('../../../lib/publisher')()

fs = require 'fs'
fixturesPath = fs.realpathSync(
  __dirname +
  '/../../fixtures'
)
describe "Publisher", ->

  publisher = false

  beforeEach ->
    class PublisherMock extends Publisher
      constructor: ->

    publisher = new PublisherMock()

  describe "parseSiteChefFile", ->
    it "Should parse sitechef file correctly", ->

      publisher.configOverride = fixturesPath + '/siteChefConfig'
      publisher.parseSiteChefFile(true)

      expect(publisher.config.code)
        .toBe 'demo-code'

      expect(publisher.apiKey)
        .toBe 'demo-code'

  describe "parseSiteChefIgnore", ->

    it "should read file correctly and set ignore files", ->
      publisher.configOverride = fixturesPath + '/.sitechefrc'

      publisher.parseSiteChefIgnore()

      expect(publisher.ignoreFiles[0])
        .toBe 'node_modules'


