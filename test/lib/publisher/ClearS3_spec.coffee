ClearS3 = require '../../../lib/publisher/ClearS3'

nock = require 'nock'

describe "ClearS3", ->

  it "Should perform delete request to " +
  "'https://localhost:8010/theme'", (done) ->
    nock('https://themes.sitechef.co.uk'
      ,
        'X-Api-Auth':'apicode'
    )
      .delete('/theme')
      .reply 200
      ,
        success: true

    ClearS3 'apicode', (err, res) ->
      throw err if err
      expect(res.success).toBe true
      done()
