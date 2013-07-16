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
    
    // hookup add button
    $('input[type=button].add_options').on('click', function() { self.add_options(); });
    
    // hookup setup edit/remove links
    $('div#options_wrapper').on('click', 'a.action_link_edit', function(){ self.edit_option($(this)); return false; });
    $('div#options_wrapper').on('click', 'a.action_link_remove', function(){ self.remove_option($(this)); return false; });
    
    // setup the tokenInput control
    $('input[type=text].add_options').tokenInput(params.suggest_path, {
      theme: 'elmo',
      hintText: I18n.t('option_set.type_to_add_new'),
      noResultsText: I18n.t('option_set.none_found'),
      searchingText: I18n.t('option_set.searching'),
      resultsFormatter: self.format_token_result,
      preventDuplicates: true,
      tokenValue: 'name'
    });
  };
  
  // returns the html to insert in the token input result list
  klass.prototype.format_token_result = function(item) {
    var details, css = "details";
    // if this is the new placeholder, add a string about that
    if (item.id == null) {
      details = I18n.t('option_set.create_new');
      css = "details create_new"
    // otherwise if no option sets were returned, use the none string
    } else if (item.set_names == '')
      details = '[' + I18n.t('common.none') + ']'
    // otherwise just use item.sets verbatim
    else
      details = item.set_names;
    
    return '<li>' + item.name + '<div class="'+ css + '">' + details + '</div></li>';
  };
  
  // renders the option html to the view
  klass.prototype.render_options = function() { var self = this;
    // create outer ol tag
    var ol = $("<ol>");
    
    // add li tags
    self.option_settings.forEach(function(oing, idx){
      self.add_option_to_view(oing, ol);
    });
    
    // append to wrapper div
    ol.appendTo('div#options_wrapper');
    
    // setup the sortable plugin
    ol.nestedSortable({
      handle: 'div',
      items: 'li',
      toleranceElement: '> div',
      maxLevels: 1
    });
  };
  
  // adds an option to the view
  klass.prototype.add_option_to_view = function(optioning, ol_tag) { var self = this;
    // if we don't have ol_tag, look it up
    if (typeof(ol_tag) == 'undefined') ol_tag = $('div#options_wrapper > ol');
    
    // make inner option tag
    var inner = $('<div>').attr('class', 'inner').append(optioning.option.name);
    
    // add edit/remove
    var links = $('<div>').attr('class', 'links').append(self.params.edit_link);
    if (optioning.removable) links.append(self.params.remove_link);
    links.appendTo(inner);
    
    // add locales
    if (optioning.option.locales.length > 0)
      inner.append($('<em>').html(optioning.option.locales.join(' ')));
      
    // associate optioning with element
    inner.data('optioning', optioning);

    // append to ol
    $('<li>').html(inner).appendTo(ol_tag);
  };
  
  
  // adds options from the token input control to the view and data model
  klass.prototype.add_options = function() { var self = this;
    var chosen = $('input[type=text].add_options').tokenInput('get');
    
    // loop over chosen options
    chosen.forEach(function(opt){
      // create optioning
      var oing = {id: null, removable: true, option: opt};
      
      // add to data model
      self.option_settings.push(oing);

      // add to view
      self.add_option_to_view(oing);
    });
  };
  
  // removes an option from the view
  klass.prototype.remove_option = function(link) { var self = this;
    // remove from data model
    self.option_settings.splice(self.option_settings.indexOf(link.closest('div.inner').data('optioning')), 1);

    // remove from view
    link.closest('li').remove();
  };
  
})(ELMO);
