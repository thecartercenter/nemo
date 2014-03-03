// ELMO.Views.OptionSetForm
//
// View model for the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionSetForm = klass = function(params) { var self = this;

    self.done = false;

    self.params = params;

    // setup option set model
    self.option_set = new ELMO.Models.OptionSet(params.option_set);

    // setup OptionLevelsField view
    self.option_levels_field = new ELMO.Views.OptionLevelsField({
      wrapper: $("#option-levels-wrapper"),
      modal: $("#edit-option-level"),
      option_levels: self.option_set.option_levels,
      form_mode: self.params.form_mode,
      can_reorder: true,
      can_remove: self.params.can_remove_options,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link
    });

    // setup OptionsField view
    self.options_field = new ELMO.Views.OptionsField({
      wrapper: $("#options-wrapper"),
      modal: $("#edit-option"),
      optionings: self.option_set.optionings,
      form_mode: self.params.form_mode,
      can_reorder: self.params.can_reorder,
      can_remove: self.params.can_remove_options,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link
    });

    // add option button click event
    $('div.add_options input[type=button]').on('click', function() { self.add_options(); });

    // add option level link click event
    $('.option_set_option_levels a.add-link').on('click', function(e) {
      self.option_levels_field.add();
      e.preventDefault();
    });

    // watch for changes to multilevel property
    $('#option_set_multi_level').on('change', function() {
      // show/hide the option levels field
      self.option_levels_field.show($(this).is(':checked'));
    });

    // trigger initial change to get things rolling
    $('#option_set_multi_level').trigger('change');

    // multiselect box should be disabled unless there are 0 option levels
    self.option_levels_field.list.on('change', function(){
      $('#option_set_multi_level').prop('disabled', this.count() > 0);
    });
    self.option_levels_field.list.trigger('change');

    // setup the tokenInput control
    $('input.add_options_box').tokenInput(params.suggest_path, {
      theme: 'elmo',
      hintText: I18n.t('option_set.type_to_add_new'),
      noResultsText: I18n.t('option_set.none_found'),
      searchingText: I18n.t('option_set.searching'),
      resultsFormatter: self.format_token_result,
      preventDuplicates: true,
      tokenValue: 'name',
      onResult: function(results){ return self.process_token_results(results); },
      onAdd: function(item){ return self.token_added(item); },
      // this event hook is custom, added by tomsmyth. see the tokenInput source code.
      onEnter: function(){ self.add_options(); }
    });

    // hookup form submit
    $('form.option_set_form').on('submit', function(){ return self.form_submitted(); });

    // hookup leave page warning unless ajax request
    if (!self.params.ajax_mode)
      window.onbeforeunload = function(){
        if (self.dirty() && !self.done)
          return I18n.t('option_set.leave_page_warning');
      };
  };

  // checks if client side model is dirty
  klass.prototype.dirty = function() { var self = this;
    return self.option_set.optionings.dirty || self.option_set.option_levels.dirty;
  };

  // returns the html to insert in the token input result list
  klass.prototype.format_token_result = function(item) { var self = this;
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

  // strips duplicates from token results
  // this doesn't work if the result is cached
  klass.prototype.process_token_results = function(results) { var self = this;
    return results.filter(function(r){ return !self.option_set.optionings.has_with_name(r.name); });
  };

  // if the added token is a duplicate, delete it!
  klass.prototype.token_added = function(item) { var self = this;
    if (self.option_set.optionings.has_with_name(item.name))
      $('input.add_options_box').tokenInput("remove", {name: item.name});
  };

  // adds options from the token input control to the view and data model
  klass.prototype.add_options = function() { var self = this;
    var chosen = $('input.add_options_box').tokenInput('get');
    var ol = $('div#options-wrapper > ol');

    // loop over chosen options
    chosen.forEach(function(option_attribs){ self.options_field.add(option_attribs); });

    // clear out the add box
    $('input.add_options_box').tokenInput('clear');
  };

  // prepares the form to be submitted by setting up the right fields
  // or if in ajax mode, submits the form via ajax and returns false
  klass.prototype.form_submitted = function() { var self = this;

    // set flag so we don't raise warning on navigation
    self.done = true;

    self.submit_via_ajax();

    // so form won't submit normally
    return false;
  };

  // traverses the option tree and generates a hash representing the full option set
  // see OptionSetSubmissionTest for the expected format
  klass.prototype.prepare_data = function() { var self = this;
    // start with basic form data
    var data = $('form.option_set_form').serializeHash();
    data.option_set = {};

    // add nodes
    data.option_set._option_levels = self.prepare_option_levels();
    data.option_set._optionings = self.prepare_options();

    return data;
  };

  // prepares the list of option levels
  klass.prototype.prepare_option_levels = function() { var self = this;
    // we know the item tree in this case will be 'flat'
    return self.option_levels_field.list.item_tree().map(function(node){
      // each 'node' in the 'tree' will be a NamedItem, so we just take the name_translations hash
      return node.item.name_translations;
    });
  };

  // prepares the options, including the destroyed ones
  klass.prototype.prepare_options = function() { var self = this;
    // get the main tree
    var prepared = self.prepare_option_tree(self.options_field.list.item_tree());

    // add the destroyed optionings
    self.option_set.optionings.removed.forEach(function(o){
      prepared.push({id: o.id, _destroy: true});
    })

    return prepared;
  };

  // prepares an option tree
  // nodes - a list of the top level nodes in the tree
  klass.prototype.prepare_option_tree = function(nodes) { var self = this;
    return nodes.map(function(node){
      // in this case, the item will be an Optioning, which is also a NamedItem
      var prepared = {option: {name_translations: node.item.name_translations}};

      // include IDs if available
      if (node.item.id)
        prepared.id = node.item.id;

      if (node.item.option.id)
        prepared.option.id = node.item.option.id;

      // recurse
      if (node.children)
        prepared.optionings = self.prepare_option_tree(node.children);

      return prepared;
    });
  };

  // submits form via ajax
  klass.prototype.submit_via_ajax = function() { var self = this;

    // get data and set modal if applicable
    var data = self.prepare_data();
    if (self.params.ajax_mode)
      data.modal = 1;

    $.ajax({
      url: $('form.option_set_form').attr('action'),
      type: 'POST',
      data: data,
      success: function(data, status, jqxhr) {
        // if content type was json, that means success
        if (jqxhr.getResponseHeader('Content-Type').match('application/json')) {

          // the data holds the new option set's ID
          self.option_set.id = parseInt(data);

          // trigger the custom event
          $('form.option_set_form').trigger('option_set_form_submit_success', [self.option_set]);

        // otherwise we got an error,
        // so replace the div with the new partial (this will instantiate a new instance of this class)
        } else {
          $('div.option_set_form').replaceWith(jqxhr.responseText);
        }
      },
      error: function(jqxhr) {
        // if we get an HTTP error, it's some server thing so just display a generic message
        $('div.option_set_form').replaceWith("Server Error");
      }
    });
  };

})(ELMO.Views);
