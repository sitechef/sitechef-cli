###
# Uploads all items in the dist
# folder to s3
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
#
###

FetchJSON = require '../utilities/FetchJSON'
Defaults = require '../defaults'
S3Upload = require '../utilities/S3Upload'

async = require 'async'
glob = require 'glob'
mime = require 'mime'
path = require 'path'
os = require 'os'
uuid = require 'uuid'
zlib = require('zlib')
fs = require 'fs'
_ = require 'lodash'

###
# @param {String} theme root
# @param {String} apikey
# @param {Function} callback
# @param {Boolean} just return the class (for testing)
###
module.exports = (themeRoot, apiKey, callback, classOnly = false)->

  class UploadDist

    constructor: (@themeRoot, @apiKey, @callback) ->

      @start()

    glob: '**/*'

    S3Upload: S3Upload

    ###
    # Begins processing
    ###
    start: =>
      async.waterfall [
        ((cb) =>
          @getFileList cb
        )
        ( (files, cb) =>
          @addMime files, cb
        )
        ( (files, cb) =>
          @getPolicies files, cb
        )
        ( (policies, cb) =>
          @uploadAllFiles policies, cb
        )
      ]
      , (err, data) =>
        return @callback err if err
        @callback null, 'done'

    ###
    # Lists all files in
    # dist folder
    # @param {Function} callback
    ###
    getFileList: (cb) =>
      glob @glob
      ,
       cwd: path.join(@themeRoot, 'dist')
       nodir: true
      , cb

    ###
    # Add Mime Types
    # @param {Array} list of relative paths
    # @param {Function} callback
    ###
    addMime: (files, cb) =>
      newFiles = _.map files, (item) ->
        path: item
        contentType: mime.lookup(item)

      cb null, newFiles

    ###
    # Get Policies
    #
    # Queries Theme Api Server
    # for policies for S3
    # @param {Array} list of files with contentType
    # @param {Function} callback (err, policyArray)
    ###
    getPolicies: (fileList, cb) =>

      config = Defaults false

      url = config.themesHost + 'dist'

      FetchJSON
        url: url
        method: 'post'
        apiKey: @apiKey
        json: true
        body:
          files: fileList
      , cb

    # max concurrent uploads
    maxConcurrent: 3

    ###
    # Upload all the files
    #
    # @param {Array} Policy List
    # @param {Function} callback
    ###
    uploadAllFiles: (policies, cb)=>
      async.eachLimit policies, @maxConcurrent
      , (policy, callback) =>
        @uploadFile policy, callback
      , cb

    ###
    # Upload a file to s3
    # @param {Object} policy object
    # @param {Function} callback
    ###
    uploadFile: (policy, callback)=>
      fPath = false
      async.waterfall [
        # get the file path and generate
        # gzip version of file if necessary
        ( (cb) => @getFilePath(policy, cb))
        # upload file to s3
        ( (filePath, cb) =>
          fPath = filePath
          s3 = new @S3Upload filePath, policy, cb
        )
        # remove any gzip file
        # created temporarily
        ( (result, cb) => @deleteGzipFile(policy, fPath, cb))
      ], callback

    ###
    # Gets the file path
    # and gzip encodes
    # it if specified in policy header
    # @param {Object} policy
    # @param {Function} callback (err, filePath) ->
    ###
    getFilePath: (policy, cb) =>
      localPath = path.join(
        @themeRoot
        'dist'
        policy.localPath
      )

      unless policy.gzip
        return cb(null, localPath)
      # now gzip file
      tmpLocation = path.join(
        os.tmpdir()
        'stchf-' + uuid.v1()
      )
      input = fs.createReadStream(localPath)
      output = fs.createWriteStream(tmpLocation)

      output.on 'finish', ->
        cb null, tmpLocation

      output.on 'error', cb
      gzip = zlib.createGzip()

      input.pipe(gzip)
        .pipe(output)

    ###
    # Deletes any temporary gzip file
    # if created
    # @param {Object} policy
    # @param {String} filepath
    # @param {Function} callback
    ###
    deleteGzipFile: (policy, filePath, cb) =>
      # ignore if gzip not specified
      unless policy.gzip
        return cb(null, true)

      # make sure that filepath contains stchf
      # so we don't accidentally delete
      # a user file
      unless filePath.match /stchf/
        return cb(null, true)

      # try and delete the file
      fs.unlink filePath, cb


  if classOnly
    return UploadDist

  new UploadDist themeRoot, apiKey, callback
