###
# Downloads a zip file and expands the contents
# to the specified location
#
# --------
# Please report all bugs on the github issue page
# at github.com/sitechef/sitechef-cli/issues
# ---------
#
# @copyright Campbell Morgan, SiteChef, 2014
# @author Campbell Morgan <dev@sitechef.co.uk>
###
fs = require 'fs'
os = require 'os'
path = require 'path'
uuid = require 'uuid'
deepExtend = require 'deep-extend'
async = require 'async'
AdmZip = require 'adm-zip'
Download = require('./Download')({}, {}, true)

###
# @param {Object} config
#   {
#     src: {String} src of the zip file
#     destination: {String} full path of destination directory
#                           for the expanded zip file
#     description: {String} description for console
#     zipSaveLocation: {String|Boolean} string for the destination path of zip
#     apiKey: {String|Boolean} add an api key header
#   }
# @param {Function} callback on complete
###
module.exports = (config, callback, classOnly = false)->
  class DownloadUnzip extends Download
    defaults:
      description: false
      destination: false
      src: false
      zipSaveLocation: false
      apiKey: false

    constructor: (config, @callback)->
      @opts = deepExtend {}, @defaults, config

      @start()

    ###
    # Joins together individual actions
    ###
    start: =>
      async.auto

        downloadZip: (cb) =>
          @downloadZip cb

        expandZip: ['downloadZip', (results, cb) =>
          @expandZip results.downloadZip, cb
        ]

        removeZip: ['expandZip', (results, cb) =>
          @removeZip results.downloadZip, cb
        ]
      , (err, results) =>
        return @callback(err) if err

        @callback null, results.expandZip

    ###
    # Downloads the zip
    # file and calls back the temp location
    # on complete
    # @param {Function} callback (err, saveLocation)
    ###
    downloadZip: (cb) =>
      destination = @opts.zipSaveLocation || @getTempPath()

      @download cb, destination

    ###
    # Expands the zip file into
    # the specified directory
    # @param {String} zip location
    # @param {Function} callback
    ###
    expandZip: (zipPath, cb) =>
      zip = new AdmZip(zipPath)
      try
        zip.extractAllTo(@opts.destination)
      catch er
        return cb(er)

      cb null, @opts.destination

    ###
    # Remove Zip
    # (only performed if zipSaveLocation
    #  not specified)
    # @param {String} path of the zip file
    # @param {Function} callback
    ###
    removeZip: (zipPath, cb) =>
      if @opts.zipSaveLocation
        return cb()

      fs.unlink zipPath, cb

    ###
    # Gets the temp path for the zip file
    ###
    getTempPath: ->
      path.join(
        os.tmpdir()
        , 'stcf' + uuid.v1() + '.zip'
      )

  if classOnly
    return DownloadUnzip

  new DownloadUnzip(config, callback)
