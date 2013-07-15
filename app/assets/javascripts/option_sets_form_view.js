// ELMO.OptionSetsFormView
//
// View model for the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionSetsFormView = klass = function(params) { var self = this;
    self.params = params;
    
    // setup the tokenInput control
    $("input[type=text].add_options").tokenInput(params.suggest_path, {
      theme: 'elmo',
      hintText: I18n.t('option_set.type_to_add_new'),
      noResultsText: I18n.t('option_set.none_found'),
      searchingText: I18n.t('option_set.searching'),
      resultsFormatter: self.format_token_result
    });
  }
  
  klass.prototype.format_token_result = function(item) {
    var details, css = "details";
    // if this is the new placeholder, add a string about that
    if (item.id == '') {
      details = I18n.t('option_set.create_new');
      css = "details create_new"
    // otherwise if no option sets were returned, use the none string
    } else if (item.sets == '')
      details = '[' + I18n.t('common.none') + ']'
    // otherwise just use item.sets verbatim
    else
      details = item.sets;
    
    return '<li>' + item.name + '<div class="'+ css + '">' + details + '</div></li>';
  }
  
})(ELMO);
