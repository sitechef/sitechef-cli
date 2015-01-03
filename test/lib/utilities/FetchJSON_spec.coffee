FetchJSON = require('../../../lib/utilities/FetchJSON')({},{},true)

describe "FetchJSON", ->
  fetchMock = false
  beforeEach ->
    class FetchMock extends FetchJSON
      constructor: ->

    fetchMock = new FetchMock()

  describe "buildOptions", ->

    it "Should generate Request options", ->

      fetchMock.opts =
        method: 'POST'
        url: 'test-url'
        json: false
        body: 'test-body'
        apiKey: 'test-api'

      result = fetchMock.buildOptions()

      expect(result.method)
        .toBe 'POST'
      expect(result.headers['X-Api-Auth'])
        .toBe 'test-api'

      expect(result.body).toBe 'test-body'

