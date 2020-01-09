/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// For the tags on the questions index page.
ELMO.Views.QuestionsTagsView = class QuestionsTagsView extends ELMO.Views.ApplicationView {
  get el() { return '.tags'; }

  get events() { return { 'click .badge': 'addToSearch' }; }

  addToSearch(e) {
    e.stopPropagation();
    return ELMO.searchFormView.setQualifier('tag', e.currentTarget.innerText.trim());
  }
};
