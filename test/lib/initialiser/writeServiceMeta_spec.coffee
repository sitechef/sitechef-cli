WriteMeta = require(
  '../../../lib/initialiser/writeServiceMeta'
)
fs = require 'fs'

describe "WriteServiceMeta", ->

  removeFiles = ->
    try
      fs.unlinkSync '/tmp/test/.sitechef/.conf'
      fs.rmdirSync '/tmp/test/.sitechef'
      fs.rmdirSync '/tmp/test'
    catch e
      "error"

  beforeEach removeFiles
  afterEach removeFiles

  it "Should write the meta file", (done) ->
    fs.mkdirSync '/tmp/test'
    fs.mkdirSync '/tmp/test/.sitechef'
    WriteMeta 'demo-code'
    ,'/tmp/test'
    , (err, dest) ->
      expect(dest).toBe '/tmp/test/.sitechef/.conf'

      data = JSON.parse(fs.readFileSync(dest))
      expect(data.code)
        .toBe 'demo-code'
      expect(data.createdAt.length)
        .toBeGreaterThan 2
      expect(data.lastPublished)
        .toBe false
      done()

