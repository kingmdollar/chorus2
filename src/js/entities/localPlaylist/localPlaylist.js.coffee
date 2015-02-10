###
  Custom saved playlists, saved in local storage
###
@Kodi.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  API =

    savedFields: ['id', 'position', 'file', 'type', 'label', 'thumbnail', 'artist', 'album', 'artistid', 'artistid', 'tvshowid', 'tvshow', 'year', 'rating', 'duration', 'track', 'url']

    playlistKey: 'localplaylist:list'
    playlistItemNamespace: 'localplaylist:item:'
    thumbsUpNamespace: 'thumbs:'

    getPlaylistKey: (key) ->
      @playlistItemNamespace + key

    getThumbsKey: (media) ->
      @thumbsUpNamespace + media

    ## Get a collection of lists
    getListCollection: (type = 'list') ->
      collection = new Entities.localPlaylistCollection()
      collection.fetch()
      collection.where {type: type}
      collection

    addList: (model) ->
      collection = @getListCollection()
      model.id = @getNextId()
      collection.create(model)
      model.id

    getNextId: ->
      collection = API.getListCollection()
      items = collection.getRawCollection()
      if items.length is 0
        nextId = 1
      else
        lastItem = _.max items, (item) -> item.id
        nextId = lastItem.id + 1
      nextId

    ## Get a collection of playlist items.
    getItemCollection: (listId) ->
      collection = new Entities.localPlaylistItemCollection([], {key: listId})
      collection.fetch()
      collection

    ## Add a collection to a playlist
    addItemsToPlaylist: (playlistId, collection) ->
      items = collection.getRawCollection()
      collection = @getItemCollection playlistId
      for position, item of items
        collection.create API.getSavedModelFromSource(item, position)
      collection

    getSavedModelFromSource: (item, position) ->
      newItem = {}
      for fieldName in @savedFields
        if item[fieldName]
          newItem[fieldName] = item[fieldName]
      newItem.position = position
      idfield = item.type + 'id'
      newItem[idfield] = item[idfield]
      newItem

    ## remove all items from a list
    clearPlaylist: (playlistId) ->
      collection = @getItemCollection playlistId
      while model = collection.first()
        model.destroy()
      return


  ## The a list reference
  class Entities.localPlaylist extends Entities.Model
    defaults:
      id: 0
      name: ''
      media: '' ## song / movie / artist / etc.
      type: 'list' ## list / thumbsup / local

  ## The a list reference collection
  class Entities.localPlaylistCollection extends Entities.Collection
    model: Entities.localPlaylist
    localStorage: new Backbone.LocalStorage API.playlistKey


  ## The saved list item
  class Entities.localPlaylistItem extends Entities.Model
    idAttribute: "position"
    defaults: ->
      fields = {}
      for f in API.savedFields
        fields[f] = ''
      fields

  ## The config collection
  class Entities.localPlaylistItemCollection extends Entities.Collection
    model: Entities.localPlaylistItem
    initialize: (model, options) ->
      @localStorage = new Backbone.LocalStorage API.getPlaylistKey(options.key)


  ###
    Saved Playlists
  ###

  ## Handler to save a new playlist
  App.reqres.setHandler "localplaylist:add:entity", (name, media, type = 'list') ->
    API.addList {name: name, media: media, type: type}

  ## Handler to remove a playlist
  App.commands.setHandler "localplaylist:remove:entity", (id) ->
    collection = API.getListCollection()
    model = collection.findWhere {id: parseInt(id)}
    model.destroy()

  ## Handler to get saved lists
  App.reqres.setHandler "localplaylist:entities", ->
    API.getListCollection()

  ## Handler to clear all items from a list
  App.commands.setHandler "localplaylist:clear:entities", (playlistId) ->
    API.clearPlaylist(playlistId)

  ## Handler to get a single saved list
  App.reqres.setHandler "localplaylist:entity", (id) ->
    collection = API.getListCollection()
    collection.findWhere {id: parseInt(id)}

  ## Handler to get list items
  App.reqres.setHandler "localplaylist:item:entities", (key) ->
    API.getItemCollection key

  ## Handler to add items to a playlist
  App.reqres.setHandler "localplaylist:item:add:entities", (playlistId, collection) ->
    API.addItemsToPlaylist playlistId, collection


  ###
    Thumbs up lists
  ###

  ## Handler togle thumbs up on an entity
  App.reqres.setHandler "thumbsup:toggle:entity", (model) ->
    media = model.get('type')
    collection = API.getItemCollection API.getThumbsKey(media)
    position = if collection then collection.length + 1 else 1
    existing = collection.findWhere {id: model.get('id')}
    if existing
      existing.destroy()
    else
      collection.create(API.getSavedModelFromSource(model.attributes, position))
    collection

  ## Handler to get a thumbs up collection
  App.reqres.setHandler "thumbsup:get:entities", (media) ->
    API.getItemCollection API.getThumbsKey(media)

  App.reqres.setHandler "thumbsup:check", (model) ->
    collection = API.getItemCollection API.getThumbsKey(model.get('type'))
    existing = collection.findWhere {id: model.get('id')}
    _.isObject(existing)