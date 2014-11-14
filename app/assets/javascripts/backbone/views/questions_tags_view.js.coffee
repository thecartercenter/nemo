# For the tags on the questions index page.
class ELMO.Views.QuestionsTagsView extends Backbone.View

  el: 'ul.tags'

  events:
    'click li': 'add_to_search'

  add_to_search: (e) ->
    e.stopPropagation()
    searchFormView.setQualifier 'tag', e.currentTarget.innerText.trim()
