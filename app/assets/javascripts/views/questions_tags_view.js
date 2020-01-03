/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// For the tags on the questions index page.
(ELMO.Views.QuestionsTagsView = class QuestionsTagsView extends ELMO.Views.ApplicationView {
  static initClass() {
    this.prototype.el = '.tags';

    this.prototype.events = { 'click .badge': 'addToSearch' };
  }

  addToSearch(e) {
    e.stopPropagation();
    return ELMO.searchFormView.setQualifier('tag', e.currentTarget.innerText.trim());
  }
}).initClass();
