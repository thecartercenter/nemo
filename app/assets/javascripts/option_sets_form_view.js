// ELMO.OptionSetsFormView
//
// View model for the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionSetsFormView = klass = function(params) { var self = this;
    self.params = params;
    self.option_settings = params.option_settings;
    
    // render the options
    self.render_options();
    
    // setup the tokenInput control
    $("input[type=text].add_options").tokenInput(params.suggest_path, {
      theme: 'elmo',
      hintText: I18n.t('option_set.type_to_add_new'),
      noResultsText: I18n.t('option_set.none_found'),
      searchingText: I18n.t('option_set.searching'),
      resultsFormatter: self.format_token_result,
      preventDuplicates: true
    });
  };
  
  // returns the html to insert in the token input result list
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
  };
  
  // renders the option html to the view
  klass.prototype.render_options = function() { var self = this;
    // create outer ol tag
    var ol = $("<ol>");
    
    // add li tags
    self.option_settings.forEach(function(oing){
      // make inner option tag
      var inner = $('<div>').append(oing.option.name);
      if (oing.option.locales.length > 0)
        inner.append($('<em>').html(oing.option.locales.join(', ')))

      $('<li>').html(inner).appendTo(ol);
    });
    
    // append to wrapper div
    ol.appendTo('div#options_wrapper');
    
    // setup the sortable plugin
    ol.nestedSortable({
      handle: 'div',
      items: 'li',
      toleranceElement: '> div',
      maxLevels: 2
    });
  };
  
})(ELMO);
