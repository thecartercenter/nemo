class ELMO.Views.UserGroupsModalView extends Backbone.View
  el: '#user-groups-modal'

  initialize: (params) ->
    @params = params
    @set_body(params.html)

  set_body: (html) ->
    @$('.modal-body').html(html)

  show: ->
    $(@el).modal('show')
