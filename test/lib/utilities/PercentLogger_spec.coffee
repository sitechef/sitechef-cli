PercentLogger = require '../../../lib/utilities/PercentLogger'

class PercentMock extends PercentLogger
  constructor: ->

class ProgressMock
  constructor: (@message)->
  tick: (amount) ->


describe "PercentLogger", ->

  pL = false
  mockRequest = false

  beforeEach ->
    pL = new PercentMock()
    pL.Progress = ProgressMock

    mockRequest =
      req:
        connection:
          socket:
            _bytesDispatched: 0

  describe "getPercent", ->


    it "should return 101 if complete", ->
      pL.completed = true

      expect(pL.getPercent(mockRequest, 100))
        .toBe 101

    it "should return 0 if request not available", ->
      expect(pL.getPercent({}, 100))
        .toBe 0

    it "should return percent of fileSize if req specified", ->
      mockRequest.req.connection.socket._bytesDispatched = 20

      # 101 put in to test Math.ceil
      expect(pL.getPercent(mockRequest, 101))
        .toBe 20


  describe "logUpload", ->

    it "should 'tick' if diff greater than 0", (done)->
      pL.bar = new ProgressMock('test message')
      spyOn(pL.bar, 'tick')

      # add 10 bytes to bytes dispatched
      timer = setInterval ->
        mockRequest.req.connection.socket._bytesDispatched+= 10
      , 10

      pL.opts =
        pollDelay: 5

      pL.logUpload mockRequest, 100

      setTimeout ->
        expect(pL.bar.tick.calls.count())
          .toBe 11

        done()
      , 120





