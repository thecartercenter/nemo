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
      $('<li>').html(self.render_option(oing)).appendTo(ol);
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
  
  // builds the inner div tag for an option
  klass.prototype.render_option = function(optioning) { var self = this;
    // make inner option tag
    optioning.div = $('<div>').attr('class', 'inner').append(optioning.option.name);
    
    // add edit/remove
    var links = $('<div>').attr('class', 'links').append(self.params.edit_link);
    if (optioning.removable) links.append(self.params.remove_link);
    links.appendTo(optioning.div);
    
    // add locales
    var locales = Object.keys(optioning.option.name_translations).filter(function(l){ 
      return optioning.option.name_translations[l] && optioning.option.name_translations[l] != ''; 
    });
    if (locales.length > 0)
      optioning.div.append($('<em>').html(locales.join(' ')));
      
    // associate optioning with element
    optioning.div.data('optioning', optioning);

    return optioning.div;
  };
  
  
  // adds options from the token input control to the view and data model
  klass.prototype.add_options = function() { var self = this;
    var chosen = $('input[type=text].add_options').tokenInput('get');
    var ol = $('div#options_wrapper > ol');
    
    // loop over chosen options
    chosen.forEach(function(opt){
      // create optioning
      var oing = {id: null, removable: true, option: opt};
      
      // add to data model
      self.option_settings.push(oing);

      // wrap in li and add to view
      $('<li>').html(self.render_option(oing)).appendTo(ol);
    });
    
    // clear out the add box
    $('input[type=text].add_options').tokenInput('clear');
  };
  
  // removes an option from the view
  klass.prototype.remove_option = function(link) { var self = this;
    // remove from data model
    self.option_settings.splice(self.option_settings.indexOf(link.closest('div.inner').data('optioning')), 1);

    // remove from view
    link.closest('li').remove();
  };

  // shows the edit dialog
  klass.prototype.edit_option = function(link) { var self = this;
    // get the oing model object
    var oing = link.closest('div.inner').data('optioning');
    
    // clear the text boxes
    ELMO.app.params.mission_locales.forEach(function(locale){
      $('div.edit_option_form input#name_' + locale).val("");
    });

    // then populate text boxes
    for (var locale in oing.option.name_translations)
      $('div.edit_option_form input#name_' + locale).val(oing.option.name_translations[locale]);

    // create the dialog
    $("div.edit_option_form").dialog({
      dialogClass: "no-close edit_option_modal",
      buttons: [
        {text: I18n.t('common.cancel'), click: function() { $(this).dialog('close'); }},
        {text: I18n.t('common.save'), click: function() { self.save_option(oing); }}
      ],
      modal: true,
      autoOpen: true,
      width: 500,
      height: 150 + (ELMO.app.params.mission_locales.length * 40)
    });
  };
  
  // saves entered translations to data model
  klass.prototype.save_option = function(optioning) { var self = this;
    $('div.edit_option_form input[type=text]').each(function(){
      // save the data
      var new_val = $(this).val().trim();
      var locale = $(this).data('locale');
      optioning.option.name_translations[locale] = new_val;
      if (locale == I18n.locale)
        optioning.option.name = new_val;
    });

    // re-render the option in the view
    var old_div = optioning.div;
    old_div.replaceWith(self.render_option(optioning));
    
    $('div.edit_option_form').dialog('close');
  }
  
})(ELMO);
