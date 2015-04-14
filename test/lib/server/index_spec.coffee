Server = require('../../../lib/server')()

describe "Server/index", ->

  server = false

  beforeEach ->
    class ServerMock extends Server
      constructor: ->

    server = new ServerMock()


  describe 'filterPagesById', ->
    it "should index all items by id which are not api calls", ->
      data =
        '/api/item1':
          content:
            name: 'no'
            id: 28
        '/my-url':
          content:
            name: 'yes'
            id: 2
      server.data = data
      server.filterPagesById()
      expect(server.pagesById[2].name)
        .toBe 'yes'

      expect(server.pagesById[29])
        .toBe undefined

  describe 'updateIsMobile', ->

    it "Should recurse through updating isMobile," +
    " without affecting other nested objects", ->
      demoData =
        prefs: [
          {
            item1: 'test'
            item2: [
              {
                subItem1: 'subItem'
                isMobile: false
              }
            ]
          }
        ]
        extra:
          isMobile: false

      result = server.updateIsMobile(demoData, true)

      expect(
        result.prefs[0].item2[0].isMobile
      ).toBe true

      expect(
        result.extra.isMobile
      ).toBe true


  describe "mobileCheck", ->
    it "should not update mobile data if not mobile", ->
      desktopAgent = "Mozilla/5.0" +
      "AppleWebKit/537.36 (KHTML, like Gecko) " +
      "Chrome/40.0.0.0 Safari/537.36"

      demoData =
        isMobile: false

      result = server.mobileCheck
        headers:
          'user-agent': desktopAgent
      , demoData

      expect(result.isMobile)
        .toBe false

    it "should set is mobile to true on a mobile user agent", ->
      iphoneUseragent = "Mozilla/5.0 (iPhone; CPU " +
      "iPhone OS 7_0 like Mac OS X; en-us) " +
      "AppleWebKit/537.51.1 (KHTML, like Gecko) " +
      "Version/7.0 Mobile/11A465 Safari/9537.53"

      demoData =
        isMobile: false

      result = server.mobileCheck
        headers:
          'user-agent': iphoneUseragent
      , demoData

      expect(result.isMobile).toBe true



  describe "respond", ->

    it "should call next if url not found in datafile", ->

      req =
        url: '/MYtestUrl'

      server.data =
        '/anotherUrl': {}

      next =
        next: ->

      spyOn next, 'next'

      server.respond req, {}, next.next

      expect(next.next).toHaveBeenCalled()


    it "Should call res.json with page data if xhr is true", (done)->

      req =
        url: '/testURL/anotherTEST'
        xhr: true

      res=
        json: (data) ->
          expect(data.data).toBe 'test-data'
          done()

      server.data =
        '/testurl/anothertest': {data:'test-data'}

      server.respond req, res, ->
        throw new Error("Res.json not called")

    it "Should call 'renderIframes' if widgets exist", (done) ->
      req =
        url: '/test/url'
        xhr: true

      res =
        json: (data)->

      server.renderIframes = (d, cb) ->
        expect(d.content.data).toBe 'test-data'
        cb null, d
        done()

      server.data =
        '/test/url':
          data: 'test-data'
          widgets: 'widgets'
      server.respond req, res, ->
        throw new Error("next called")

    it "should call renderIframes then render " +
    "and send successful result", (done) ->

      renderIframes = false
      server.renderIframes = (data, cb) ->
        renderIframes = true
        cb null, data

      server.render = (page, data,  cb) ->
        expect(page).toBe 'index.html'
        expect(data).toBe 'test-data'
        cb null, 'templated-text'

      req =
        url: '/test'
        xhr: false

      res =
        send: (html) ->
          expect(html).toBe 'templated-text'
          expect(renderIframes).toBe true
          done()

      server.data =
        '/test': 'test-data'

      server.respond req, res, ->
        throw new Error("Next called")

