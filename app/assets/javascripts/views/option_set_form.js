// ELMO.Views.OptionSetForm
//
// View model for the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionSetForm = klass = function(params) { var self = this;

    self.done = false;

    self.params = params;

    // setup OptionLevelsField view
    self.option_levels_field = new ELMO.Views.OptionLevelsField({
      wrapper: $("#option-levels-wrapper"),
      modal: $("#edit-option-level"),
      option_levels: params.option_set.levels,
      options_levels_read_only: self.params.options_levels_read_only,
      can_reorder: true,
      can_remove: self.params.can_remove_options,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link
    });

    // setup OptionsField view
    self.options_field = new ELMO.Views.OptionsField({
      wrapper: $("#options-wrapper"),
      modal: $("#edit-option"),
      children: params.option_set.children,
      options_levels_read_only: self.params.options_levels_read_only,
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
    $('#option_set_multi_level').on('change', function() { self.multilevel_changed(); });
    self.multilevel_changed();

    // events to enable/disable multilevel checkbox
    self.options_field.list.on('change', function(){ self.enable_multilevel_checkbox(); });
    self.option_levels_field.list.on('change', function(){ self.enable_multilevel_checkbox(); });
    self.enable_multilevel_checkbox();

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

    // Set maxlength on the inner token input box to enforce option name length on creation.
    $('#token-input-').attr('maxlength', self.params.max_option_name_length);

    // hookup form submit
    $('form.option_set_form').on('submit', function(){ return self.form_submitted(); });

    // hookup leave page warning unless ajax request
    if (!self.params.modal_mode)
      window.onbeforeunload = function(){
        if (self.dirty() && !self.done)
          return I18n.t('option_set.leave_page_warning');
      };
  };

  // checks if there have been any changes
  klass.prototype.dirty = function() { var self = this;
    return self.options_field.list.dirty || self.option_levels_field.list.dirty;
  };

  // enables/disables multi_level checkbox depending on option levels and optioning depths
  // should be disabled unless there are 0 option levels and all options have depth 1
  klass.prototype.enable_multilevel_checkbox = function() { var self = this;
    $('#option_set_multi_level').prop('disabled',
      !(self.option_levels_field.list.count() == 0 && self.options_field.list.max_depth() <= 1));
  };

  // reacts to changes to multilevel checkbox
  klass.prototype.multilevel_changed = function() { var self = this;
    var checked;
    // Check if multilevel checkbox is read only
    if ($('#multi_level div.ro-val').length > 0)
      checked = $('#multi_level div.ro-val').data('val');
    else
      checked = $('#option_set_multi_level').is(':checked');

    // show/hide the option levels field
    self.option_levels_field.show(checked);

    // enable/disable nested options
    self.options_field.list.allow_nesting(checked);
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
    return results.filter(function(r){ return !self.options_field.list.has_with_name(r.name); });
  };

  // if the added token is a duplicate, delete it!
  klass.prototype.token_added = function(item) { var self = this;
    if (self.options_field.list.has_with_name(item.name))
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

    // do client side validations
    self.clear_errors();
    if (self.validate())
      self.submit_via_ajax();

    // so form won't submit normally
    return false;
  };

  // traverses the option tree and generates a hash representing the full option set
  klass.prototype.prepare_data = function() { var self = this;
    // temporarily enable any disabled items else serialization will fail
    var disabled = $('form.option_set_form').find(':input:disabled').removeAttr('disabled');

    // get with basic form data
    var data = $('form.option_set_form').serializeHash();

    // re-disable
    disabled.attr('disabled', 'disabled');

    // Add nodes unless read only.
    if (!self.params.options_levels_read_only) {
      data.option_set = {};
      data.option_set.level_names = self.prepare_option_levels();
      data.option_set.children_attribs = self.prepare_options();
    }

    // Upate some params OptionSet model, as this may be used by modal
    self.params.option_set.name = data['option_set[name]'];
    self.params.option_set.multi_level = data['option_set[multi_level]'] == '1';

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
  // see OptionNodeSupport modules for the expected format
  klass.prototype.prepare_options = function() { var self = this;
    // get the main tree
    return self.prepare_option_tree(self.options_field.list.item_tree());
  };

  // prepares an option tree
  // nodes - a list of the top level nodes in the tree
  klass.prototype.prepare_option_tree = function(nodes) { var self = this;
    return nodes.map(function(node){
      // in this case, the item will be an Optioning, which is also a NamedItem
      var prepared = {option_attribs: {name_translations: node.item.name_translations}};

      // include IDs if available
      if (node.item.id)
        prepared.id = node.item.id;

      if (node.item.option.id)
        prepared.option_attribs.id = node.item.option.id;

      // recurse
      prepared.children_attribs = node.children ? self.prepare_option_tree(node.children) : 'NONE';

      return prepared;
    });
  };

  // submits form via ajax
  klass.prototype.submit_via_ajax = function() { var self = this;

    // get data and set modal if applicable
    var data = self.prepare_data();
    if (self.params.modal_mode)
      data.modal_mode = 1;

    // show loading
    $('form.option_set_form .loading_indicator img').show();

    $.ajax({
      url: $('form.option_set_form').attr('action'),
      type: 'POST',
      data: data,
      success: function(data, status, jqxhr) {
        // if content type was json, that means success
        if (jqxhr.getResponseHeader('Content-Type').match('application/json')) {

          // if we're in modal mode, we need to do different stuff
          if (self.params.modal_mode) {

            // the data holds the new option set's ID
            self.params.option_set.id = parseInt(data);

            // trigger the custom event
            $('form.option_set_form').trigger('option_set_form_submit_success', [self.params.option_set]);
          }

          // else, not modal mode, just redirect (URL given as json response)
          else
            window.location.href = data;

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

  klass.prototype.validate = function() { var self = this;
    var checks = ['name_presence'];
    if (!self.params.options_levels_read_only)
      checks.push('option_presence', 'option_depths');
    var valid = true;

    // Run each check even if an early one fails.
    checks.forEach(function(c) {
      if (!self['validate_' + c]()) valid = false;
    });

    return valid;
  };

  klass.prototype.validate_name_presence = function() { var self = this;
    // Ensure name field is editable.
    if ($('input#option_set_name').length == 0) return true;

    if ($('#option_set_name').val().trim() == '') {
      self.add_error('.option_set_name', I18n.t('activerecord.errors.messages.blank'));
      return false;
    }
    return true;
  };

  klass.prototype.validate_option_presence = function() { var self = this;
    if (self.options_field.list.size() == 0) {
      self.add_error('.option_set_options', I18n.t('activerecord.errors.models.option_set.at_least_one'));
      return false;
    }
    return true;
  };

  // checks if number of option levels and option depths are compatible
  // returns whether submission should proceed
  klass.prototype.validate_option_depths = function() { var self = this;
    if ($('#option_set_multi_level').is(':checked')) {
      var levels = self.option_levels_field.list.size();
      var depth = self.options_field.list.max_depth();
      if (levels != depth) {
        self.add_error('.option_set_options', I18n.t('activerecord.errors.models.option_set.wrong_depth',
          {levels: levels, depth: depth}));
        return false;
      }
    }
    return true;
  };

  // adds a validation error to the field with the given selector
  klass.prototype.add_error = function(selector, msg) { var self = this;
    $(selector + ' .control').prepend($('<div>').addClass('form-errors').html(msg));
  };

  // clears error messages
  klass.prototype.clear_errors = function() { var self = this;
    $('form.option_set_form').find('div.form-errors').remove();
  };

})(ELMO.Views);
