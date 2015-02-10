@Kodi.module "localPlaylistApp.List", (List, App, Backbone, Marionette, $, _) ->

  class List.ListLayout extends App.Views.LayoutWithSidebarFirstView
    className: "local-playlist-list"

  class List.SideLayout extends App.Views.LayoutView
    template: 'apps/localPlaylist/list/playlist_sidebar_layout'
    tagName: 'div'
    className: 'side-inner'
    regions:
      regionLists: '.current-lists'
    triggers:
      'click .new-list' : 'lists:new'

  class List.List extends App.Views.ItemView
    template: 'apps/localPlaylist/list/playlist'
    tagName: "li"
    initialize: ->
      path = helpers.url.get 'playlist', @model.get('id')
      classes = []
      if path is helpers.url.path()
        classes.push 'active'
      tag = @themeLink(@model.get('name'), path, {'className': classes.join(' ')})
      @model.set(title: tag)

  class List.Lists extends App.Views.CompositeView
    template: 'apps/localPlaylist/list/playlist_list'
    childView: List.List
    tagName: "div"
    childViewContainer: 'ul.lists'
    onRender: ->
      $('h3', @$el).html( t.gettext('Playlists') )

  class List.Selection extends App.Views.ItemView
    template: 'apps/localPlaylist/list/playlist'
    tagName: "li"
    initialize: ->
      @model.set(title: @model.get('name'))
    triggers:
      'click .item' : 'item:selected'

  class List.SelectionList extends App.Views.CompositeView
    template: 'apps/localPlaylist/list/playlist_list'
    childView: List.Selection
    tagName: "div"
    className: 'playlist-selection-list'
    childViewContainer: 'ul.lists'
    onRender: ->
      $('h3', @$el).html( t.gettext('Existing playlists') )

  class List.Layout extends App.Views.LayoutView
    template: 'apps/localPlaylist/list/playlist_layout'
    tagName: 'div'
    className: 'local-playlist'
    regions:
      regionListItems: '.item-container'
    triggers:
      'click .local-playlist-header .clear' : 'list:clear'
      'click .local-playlist-header .delete' : 'list:delete'
    onRender: ->
      if @options and @options.list
        $('h2', @$el).html( @options.list.get('name') )