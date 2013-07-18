// ELMO.OptionSetsFormView
//
// View model for the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionSetsFormView = klass = function(params) { var self = this;
    self.params = params;
    self.option_set = new ELMO.OptionSet(params.optionings);
    
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
    
    // hookup form submit
    $('form.option_set_form').on('submit', function(){ self.form_submitted(); })
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
    self.option_set.optionings.forEach(function(oing, idx){
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
    var inner = $('<div>').attr('class', 'inner').append(optioning.option.name);
    
    // add edit/remove
    var links = $('<div>').attr('class', 'links').append(self.params.edit_link);
    if (optioning.removable) links.append(self.params.remove_link);
    links.appendTo(inner);
    
    // add locales
    inner.append($('<em>').html(optioning.locale_str()));
      
    // associate optioning with data model bidirectionally
    inner.data('optioning', optioning);
    optioning.div = inner;

    return inner;
  };
  
  
  // adds options from the token input control to the view and data model
  klass.prototype.add_options = function() { var self = this;
    var chosen = $('input[type=text].add_options').tokenInput('get');
    var ol = $('div#options_wrapper > ol');
    
    // loop over chosen options
    chosen.forEach(function(opt){
      // create optioning
      var oing = new ELMO.Optioning({id: null, removable: true, option: opt});
      
      // add to data model
      self.option_set.add_optioning(oing);

      // wrap in li and add to view
      $('<li>').html(self.render_option(oing)).appendTo(ol);
    });
    
    // clear out the add box
    $('input[type=text].add_options').tokenInput('clear');
  };
  
  // removes an option from the view
  klass.prototype.remove_option = function(link) { var self = this;
    // lookup optioning object remove from option set
    self.option_set.remove_optioning(link.closest('div.inner').data('optioning'));

    // remove from view
    link.closest('li').remove();
  };

  // shows the edit dialog
  klass.prototype.edit_option = function(link) { var self = this;
    // get the optioning
    var optioning = link.closest('div.inner').data('optioning');
    
    // clear the text boxes
    ELMO.app.params.mission_locales.forEach(function(locale){
      $('div.edit_option_form input#name_' + locale).val("");
    });

    // then populate text boxes
    for (var locale in optioning.option.name_translations)
      $('div.edit_option_form input#name_' + locale).val(optioning.option.name_translations[locale]);

    // create the dialog
    $("div.edit_option_form").dialog({
      dialogClass: "no-close edit_option_modal",
      buttons: [
        {text: I18n.t('common.cancel'), click: function() { $(this).dialog('close'); }},
        {text: I18n.t('common.save'), click: function() { self.save_option(optioning); }}
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
      optioning.update_translation({field: 'name', locale: $(this).data('locale'), value: $(this).val()});
    });

    // re-render the option in the view
    var old_div = optioning.div;
    old_div.replaceWith(self.render_option(optioning));
    
    $('div.edit_option_form').dialog('close');
  };
  
  // write the data model to the form as hidden tags so that the data will be included in the submission
  klass.prototype.form_submitted = function() { var self = this;
    var form = $('form.option_set_form');
    self.option_set.optionings.forEach(function(optioning, idx){
      if (optioning.id)
        self.add_form_field('option_set[optionings_attributes][' + idx + '][id]', optioning.id);
      self.add_form_field('option_set[optionings_attributes][' + idx + '][rank]', optioning.div.closest('li').index() + 1);
      if (optioning.option.id)
        self.add_form_field('option_set[optionings_attributes][' + idx + '][option_id]', optioning.option.id);
      else
        for (var locale in optioning.option.name_translations)
          self.add_form_field('option_set[optionings_attributes][' + idx + '][option_attributes][name_' + locale + ']', optioning.option.name_translations[locale]);
    });
    
    // add removed optionings
    self.option_set.removed_optionings.forEach(function(optioning, idx){
      self.add_form_field('option_set[optionings_attributes][_' + idx + '][id]', optioning.id);
      self.add_form_field('option_set[optionings_attributes][_' + idx + '][_destroy]', 'true');
    })
  };
  
  // adds a hidden form field with the given name and value
  klass.prototype.add_form_field = function(name, value) { var self = this;
    $('form.option_set_form').append($('<input>').attr('type', 'hidden').attr('name', name).attr('value', value));
  };
  
  
})(ELMO);
