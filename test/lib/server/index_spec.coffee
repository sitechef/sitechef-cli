Server = require('../../../lib/server')()

describe "Server/index", ->

  server = false

  beforeEach ->
    class ServerMock extends Server
      constructor: ->

    server = new ServerMock()


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

