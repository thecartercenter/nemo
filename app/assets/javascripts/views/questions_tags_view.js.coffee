# For the tags on the questions index page.
class ELMO.Views.QuestionsTagsView extends ELMO.Views.ApplicationView

  el: '.tags'

  events:
    'click .badge': 'addToSearch'

  addToSearch: (e) ->
    e.stopPropagation()
    ELMO.searchFormView.setQualifier 'tag', e.currentTarget.innerText.trim()
