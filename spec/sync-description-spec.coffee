SyncDescription = require '../lib/sync-description'
{Directory, File} = require 'pathwatcher'
path = require 'path'

describe 'SyncDescription', ->

  fixtureDir = ->
    root = atom.project.getRootDirectory()
    new Directory(path.join root.getRealPathSync(), 'sync-description')

  fixturePath = (names...) ->
    dirname = fixtureDir().getRealPathSync()
    path.join dirname, names...

  withDescription = (subpath, callback) ->
    root = fixtureDir().getRealPathSync()
    d = new Directory fixturePath subpath[..-2]...
    f = new File fixturePath subpath...

    sd = null
    SyncDescription.createFrom f, d, (err, instance) ->
      if err
        console.log err
        callback(null)
      sd = instance

    waitsFor -> sd?
    runs -> callback(sd)

  it 'finds all .cloud-sync.json files in the project', ->
    dirs = []

    SyncDescription.findAllIn fixtureDir(), (err, desc) ->
      dirs.push(desc.directory.getBaseName())

      if dirs.length is 3
        expect(dirs).toContain('bar')
        expect(dirs).toContain('foo')
        expect(dirs).toContain('parent')
      expect(dirs.length > 3).not.toBe(true)

  it 'finds a .cloud-sync.json in a parent directory', ->
    sd = null
    SyncDescription.withNearest fixturePath('parent', 'child'), (err, desc) ->
      expect(err).toBeNull()
      sd = desc

    waitsFor -> sd?
    runs ->
      rp = sd.directory.getRealPathSync()
      expect(rp).toBe(fixturePath 'parent', '.cloud-sync.json')

  it 'returns null if no .cloud-sync.json files exist', ->

  it 'parses configuration data from .cloud-sync.json', ->
    withDescription ['bar', '.cloud-sync.json'], (sd) ->
      expect(sd.container).toBe('magic')
      expect(sd.psuedoDirectory).toBe('somedir/')

  it 'defaults the psuedoDirectory to /', ->
    withDescription ['foo', '.cloud-sync.json'], (sd) ->
      expect(sd.psuedoDirectory).toBe('/')

  describe 'finding CloudCredentials', ->

    itLoadsCredentials = (path, creduser) ->
      c = null
      withDescription path, (sd) ->
        sd.withCredentials (err, creds) ->
          console.log err if err
          c = creds

      waitsFor -> c?
      runs -> expect(c.username).toBe(creduser)

    it 'finds CloudCredentials if provided locally', ->
      itLoadsCredentials ['foo', '.cloud-sync.json'], 'foo'

    it 'finds CloudCredentials by walking the filesystem', ->
      itLoadsCredentials ['bar', '.cloud-sync.json'], 'defaultuser'
