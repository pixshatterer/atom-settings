RokuDeployView = require './roku-deploy-view'
{CompositeDisposable} = require 'atom'
fs = require 'fs'
Archiver = require 'archiver'
request = require 'request'

module.exports = RokuDeploy =
  rokuDeployView: null
  modalPanel: null
  subscriptions: null
  rokuAddress: null
  rokuPassword: null
  rokuUserId: null
  excludedPaths: null
  outputDirectory: null
  config:
      rokuAddress:
          type: 'string'
          default: '192.168.1.1'
      rokuUserId:
          type: 'string'
          default: 'rokudev'
      rokuPassword:
          type: 'string'
          default: '1111'
      excludedPaths:
          type: 'string'
          default: 'out'
      outputDirectory:
          type: 'string'
          default: 'out'

  activate: (state) ->
    @rokuDeployView = new RokuDeployView(state.rokuDeployViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @rokuDeployView.getElement(), visible: false)
    @rokuAddress = atom.config.get('roku-deploy.rokuAddress')
    @rokuUserId = atom.config.get('roku-deploy.rokuUserId')
    @rokuPassword = atom.config.get('roku-deploy.rokuPassword')
    @excludedPaths = atom.config.get('roku-deploy.excludedPaths')
    @outputDirectory = atom.config.get('roku-deploy.outputDirectory')
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    console.log 'roku-deploy activated'
    # Register command that shows this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'roku-deploy:deployRoku': => @deployRoku()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @rokuDeployView.destroy()

  serialize: ->
    rokuDeployViewState: @rokuDeployView.serialize()

  addToZip: (dir) ->
    console.log dir.getRealPathSync()
    @zip.directory dir.getRealPathSync(), dir.getBaseName()


  zipPackage: ->
      console.log 'zipPackage called.'
      request.post('http://' + module.exports.rokuAddress + ':8060/keypress/Home').on('error', (err)-> console.log err)
      dirs = atom.project.getDirectories()
      dir = dirs[0]
      if(dir!=undefined)
          p = dir.getRealPathSync()
          bundlePath = p+'\\' + @outputDirectory + '\\'
          try
              stat = fs.lstatSync(bundlePath)
          catch error
              console.log 'out directory not found, creating.'
              fs.mkdirSync(bundlePath)
              stat = fs.lstatSync(bundlePath)
              if(not stat.isDirectory())
                  console.log 'failed to create out directory.'
                  return

          zipFile = fs.createWriteStream(bundlePath+'bundle.zip')
          @zip = Archiver('zip')
          zipFile.on('close',@zipComplete)
          @zip.on('error',(err) -> throw err)
          @zip.pipe(zipFile)
          splitExcludedPaths = @excludedPaths.split(',')
          upperExcludedPaths = []
          splitExcludedPaths.forEach (ep) -> upperExcludedPaths.push(ep.trim().toLocaleUpperCase())
          @addToZip directory for directory in dir.getEntriesSync() when directory.isDirectory() and upperExcludedPaths.indexOf(directory.getBaseName().toLocaleUpperCase()) == -1 and not directory.getBaseName().startsWith('.')
          params = {expand: true, cwd: dir.getRealPathSync(), src: ['manifest'],dest:''}
          @zip.bulk params
      @zip.finalize()

  zipComplete: ->
      console.log "Zipping complete"
      atom.notifications.addInfo("Bundling completed. Starting deploy . . .")
      addrs = 'http://'+ module.exports.rokuAddress + '/plugin_install'
      console.log  addrs
      dirs = atom.project.getDirectories()
      dir = dirs[0]
      p = dir.getRealPathSync()
      bundlePath = p+'\\' + module.exports.outputDirectory + '\\'
      rokuOptions =
          url : addrs
          formData :
              mysubmit : 'Replace'
              archive : fs.createReadStream(bundlePath+'bundle.zip')
      request.post(rokuOptions,module.exports.requestCallback).auth(module.exports.rokuUserId,module.exports.rokuPassword,false).on('error', (err)-> console.log err)
      console.log 'Request started'


  requestCallback: (error,response,body) ->
      atom.notifications.addSuccess('Deployed to '+module.exports.rokuAddress)
      console.log response.statusCode

  setRokuAddress: (address, userId,pwd)->
      module.exports.rokuAddress = address
      module.exports.rokuUserId = userId
      moduel.exports.rokuPassword = pwd
    #   Diplay input for setting roku address

  deployRoku: ->
      @rokuAddress = atom.config.get('roku-deploy.rokuAddress')
      @rokuUserId = atom.config.get('roku-deploy.rokuUserId')
      @rokuPassword = atom.config.get('roku-deploy.rokuPassword')
      @excludedPaths = atom.config.get('roku-deploy.excludedPaths')
      @outputDirectory = atom.config.get('roku-deploy.outputDirectory')
      @zipPackage()