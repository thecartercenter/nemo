class ELMO.Views.UserProfileFormView extends Backbone.View
  el: "form.user_form"

  initialize: (params) ->
    @params = params
    @user_group_options_url = params.user_group_options_url
    @user_group_select = @$("#user_user_group_ids")
    @init_user_group_select()

  init_user_group_select: ->
    @user_group_select.select2
      tags: true
      templateResult: @format_suggestions
      ajax:
        url: @user_group_options_url
        dataType: "json"
        delay: 250
        cache: true
        processResults: (data) -> {results: data}

  format_suggestions: (item) ->
    if item.id == item.text
      return $('<li><i class="fa fa-fw fa-plus-circle"></i>' + item.text +
      ' <span class="details create_new">[' + I18n.t('user_group.new_group') + ']</span>' + '</li>');
    else
      return item.text
