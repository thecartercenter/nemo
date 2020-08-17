/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Models the form for entering a search query.
ELMO.Views.SearchFormView = class SearchFormView extends ELMO.Views.ApplicationView {
  get el() { return '.search-form'; }

  get events() {
    return {
      'click .btn-clear': 'clear_search',
      'click .search-footer a': 'show_help',
    };
  }

  clear_search(e) {
    e.preventDefault();
    return window.location.href = window.location.pathname;
  }

  show_help(e) {
    e.preventDefault();
    return $('#search-help-modal').modal('show');
  }

  /**
   * Add or replace the specified search qualifier.
   * @deprecated - Use the newer Filters#submitSearch method instead.
   */
  setQualifier(qualifier, val) {
    const search_box = this.$('.search-str');
    let current_search = search_box.val();

    // Remove the qualifier text if it's already in the current search
    const regex = new RegExp(`${qualifier}:\\s*(\\w+|\\(.*\\)|".*")\\s?`, 'g');
    current_search = current_search.replace(regex, '').trim();

    // Surround new value with quotes if contains space
    val = val.replace(/^(.*\s+.*)$/, '"$1"');

    // Add new qualifier to end of search
    if (current_search) {
      search_box.val(`${current_search} ${qualifier}:${val}`);
    } else {
      search_box.val(`${qualifier}:${val}`);
    }

    // Submit form
    return this.$el.submit();
  }
};
