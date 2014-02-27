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
      modal: $("#edit-option-level"),
      optionings: self.option_set.optionings,
      form_mode: self.params.form_mode,
      can_reorder: self.params.can_reorder,
      can_remove: self.params.can_remove_options,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link
    });

    // hookup add button
    $('div.add_options input[type=button]').on('click', function() { self.add_options(); });

    // watch for changes to multilevel property
    $('#option_set_multi_level').on('change', function() { self.option_levels_field.show($(this).is(':checked')); });
    $('#option_set_multi_level').trigger('change');

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
    return self.option_set.optionings.dirty;
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

  // write the data model to the form as hidden tags so that the data will be included in the submission
  klass.prototype.form_submitted = function() { var self = this;
    // copy form values to model
    self.option_set.name = $('#option_set_name').val();
    self.option_set.geographic = $('#option_set_geographic').is(':checked');
    self.option_set.multi_level = $('#option_set_multi_level').is(':checked');

    // add fields to form to represent the options, optionings, etc.
    self.option_set.optionings.get().forEach(function(optioning, idx){

      // optioning id
      if (optioning.id)
        self.add_form_field('option_set[optionings_attributes][' + idx + '][id]', optioning.id);

      // rank
      self.add_form_field('option_set[optionings_attributes][' + idx + '][rank]', optioning.rank());

      // option attribs (only allowed if optioning is editable)
      if (optioning.editable) {

        // id
        self.add_form_field('option_set[optionings_attributes][' + idx + '][option_attributes][id]', optioning.option.id);

        optioning.locales().forEach(function(l){
          self.add_form_field('option_set[optionings_attributes][' + idx + '][option_attributes][name_' + l + ']', optioning.translation(l));
        });

      // else (optioning is not editable) just include ref to option
      } else

        self.add_form_field('option_set[optionings_attributes][' + idx + '][option_id]', optioning.option.id);

    });

    // add removed optionings with _destroy flag
    self.option_set.optionings.removed.forEach(function(optioning, idx){

      self.add_form_field('option_set[optionings_attributes][_' + idx + '][id]', optioning.id);
      self.add_form_field('option_set[optionings_attributes][_' + idx + '][_destroy]', 'true');

    });

    // set flag so we don't raise warning on navigation
    self.done = true;

    // if the form is in ajax mode, submit via ajax
    if (self.params.ajax_mode) {
      $.ajax({
        url: $('form.option_set_form').attr('action'),
        type: 'POST',
        data: $('form.option_set_form').serialize(),
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

      // return false so the form won't submit normally
      return false;

    } else
      // if not in ajax mode, just return true and let form submit normally
      return true;

  };

  // adds a hidden form field with the given name and value
  klass.prototype.add_form_field = function(name, value) { var self = this;
    $('form.option_set_form').append($('<input>').attr('type', 'hidden').attr('name', name).attr('value', value));
  };

})(ELMO.Views);
