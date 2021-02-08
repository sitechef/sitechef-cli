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
            randomItem: false
            nullItem: null
            item2: [
              {
                subItem1: 'subItem'
                otherData: false
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
        result.prefs[0].item2[0].subItem1
      ).toBe 'subItem'

      expect(
        result.prefs[0].nullItem
      ).toBe null

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

    beforeEach ->
      server.mobileCheck = (r, data) ->
        data

    it "should call next if url not found in datafile", ->

      req =
        url: '/MYtestUrl'
        path: '/MytestUrl'
        method: 'GET'

      server.customData = {}

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
        method: 'GET'

      res=
        json: (data) ->
          expect(data.data).toBe 'test-data'
          done()

      res.status = (status) ->
        expect(status).toBe(200)
        res

      server.customData = {}

      server.data =
        '/testurl/anothertest': {data:'test-data'}

      server.respond req, res, ->
        throw new Error("Res.json not called")
  describe "cleanUrl", ->
    it "should remove trailing slash", ->
      req =
        url: '/path-with/trailing-slash/'
      
      server.data =
        '/path-with/trailing-slash':
          something: 'something'
      
      result = server.cleanUrl req

      expect(result).toBe '/path-with/trailing-slash'

  describe "getData", ->
    it "should retrieve override from customdata", ->
      server.customData =
        "POST=/override_url/api": {
          templateName: 'test.html',
          status: 400
          data: {
            override: 'new'
            specialData1: 'special'
          }
        }
      server.environment = 'dev'
      server.data =
        '/':
          override: 'original'
          first: 'first'

      res = server.getData({
        method: 'POST'
        url: '/override_url/api'
        path: '/override_url/api'
      })

      expect(res.templateName).toBe('test.html')
      expect(res.status).toBe(400)
      expect(res.data.environment).toBe('dev')
      expect(res.data.override).toBe('new')
      expect(res.data.specialData1).toBe('special')
      expect(res.data.first).toBe('first')

