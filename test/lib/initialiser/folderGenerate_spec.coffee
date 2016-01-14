FolderGenerate = require(
  '../../../lib/initialiser/folderGenerate'
)({}, {}, true
,
  themesHost: 'https://sitecheftests.s3.amazonaws.com/testResponses/'
  endpoint: 'themeMeta.json'

)
fs = require 'fs'
rimraf = require 'rimraf'
exists = require '../../helpers/exists'

describe "FolderGenerate", ->
  folderGenerate = false

  beforeEach ->
    class FolderMock extends FolderGenerate
      constructor: ->

    folderGenerate = new FolderMock({}, (->))

  describe "_generateFolder", ->

    it "Should return directory override if exists", ->
      folderGenerate.opts =
        directoryOverride: 'my-folder'

      expect(folderGenerate._generateFolderName())
        .toBe 'my-folder'

    it "Should return the sanitized folder name of the meta name", ->
      folderGenerate.opts =
        directoryOverride: false
      folderGenerate.themeMeta =
          meta:
            name: 'demo023£%!^ folder'

      expect(folderGenerate._generateFolderName())
        .toBe 'demo023____-folder'


  describe "e2e", ->
    themeDir = '/tmp/siteChefTests-09/'
    removeDir = ->
      try
        rimraf.sync themeDir
      catch e
        "test"
    beforeEach removeDir
    afterEach removeDir

    it "Should create the directory and callback", (done)->
      fs.mkdirSync themeDir
      folderGenerate.opts =
        directoryOverride: false
        rootPath: themeDir

      folderGenerate.cb = (err, results) ->
        throw err if err

        expect(results.theme.meta.name)
          .toBe 'Test Site'

        expect(results.path)
          .toBe themeDir + 'test-site'

        themeRoot = themeDir + 'test-site'

        expect(exists(themeRoot))
          .toBe true

        expect(exists(themeRoot + '/.sitechef'))
          .toBe true

        done()

      folderGenerate.generate()

