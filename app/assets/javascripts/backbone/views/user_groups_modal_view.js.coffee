class ELMO.Views.UserGroupsModalView extends Backbone.View
  el: '#user-groups-modal'

  initialize: (params) ->
    this.params = params
    this.set_body(params.html)

  set_body: (html) ->
    # console.log(html)
    @modal_body = $(@el).find('.modal-body')
    console.log(@modal_body)
    $('.modal-body').html(html)
