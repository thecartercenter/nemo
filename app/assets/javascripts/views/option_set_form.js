// ELMO.Views.OptionSetForm
//
// View model for the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionSetForm = klass = function(params) { var self = this;

    self.params = params;
    self.option_set = new ELMO.Models.OptionSet(params.option_set);

    // render the options
    self.render_options();

    // setup a dirty flag
    self.dirty = false;

    // hookup add button
    $('div.add_options input[type=button]').on('click', function() { self.add_options(); });

    // hookup setup edit/remove links (deferred)
    $('div#options_wrapper').on('click', 'a.action_link_edit', function(){ self.edit_option($(this)); return false; });
    $('div#options_wrapper').on('click', 'a.action_link_remove', function(){ self.remove_option($(this)); return false; });

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


    // hookup save option button on modal
    $('#edit-option-set button.btn-primary').on('click', function(){ self.save_option(this); return false; });

    // hookup leave page warning unless ajax request
    if (!self.params.ajax_mode)
      window.onbeforeunload = function(){
        if (self.dirty)
          return I18n.t('option_set.leave_page_warning');
      };
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
    return results.filter(function(r){ return !self.option_set.has_option_with_name(r.name); });
  };

  // if the added token is a duplicate, delete it!
  klass.prototype.token_added = function(item) { var self = this;
    if (self.option_set.has_option_with_name(item.name))
      $('input.add_options_box').tokenInput("remove", {name: item.name});
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


    // setup the sortable plugin unless in show mode
    if (self.params.form_mode != 'show' && self.params.can_reorder) {
      ol.nestedSortable({
        handle: 'div',
        items: 'li',
        toleranceElement: '> div',
        maxLevels: 1,

        // set dirty flag when positions change
        change: function(){ self.dirty = true; }
      });
    }
  };

  // builds the inner div tag for an option
  klass.prototype.render_option = function(optioning) { var self = this;

    // make inner option tag
    var inner = $('<div>').attr('class', 'inner')

    // add sort icon if not in show mode
    if (self.params.form_mode != 'show' && self.params.can_reorder)
      inner.append($('<i>').attr('class', 'icon-sort'));

    // add option name (add nbsp to make sure div doesn't collapse if name is blank)
    inner.append(optioning.option.name + '&nbsp;');

    // add edit/remove unless in show mode
    if (self.params.form_mode != 'show') {
      var links = $('<div>').attr('class', 'links')

      // don't show the edit link if the option is existing and has not yet been added to the set (rails limitation)
      if (optioning.id || !optioning.option.id)
        links.append(self.params.edit_link);

      // don't show the removable link if the specific option isn't removable
      // or if the global removable permission is false
      if (self.params.can_remove_options && optioning['removable?'])
        links.append(self.params.remove_link);

      // add a spacer if empty, else it won't render right
      if (links.is(':empty'))
        links.append('&nbsp;')

      links.appendTo(inner);
    }

    // add locales
    inner.append($('<em>').html(optioning.locale_str()));

    // associate optioning with data model bidirectionally
    inner.data('optioning', optioning);
    optioning.div = inner;

    return inner;
  };


  // adds options from the token input control to the view and data model
  klass.prototype.add_options = function() { var self = this;
    var chosen = $('input.add_options_box').tokenInput('get');
    var ol = $('div#options_wrapper > ol');

    // loop over chosen options
    chosen.forEach(function(opt){
      // don't add if it's a duplicate
      if (self.option_set.has_option_with_name(opt.name)) return false;

      // dirty!
      self.dirty = true;

      // add to data model (returns new optioning)
      var oing = self.option_set.add_option(opt);

      // wrap in li and add to view
      $('<li>').html(self.render_option(oing)).appendTo(ol);
    });

    // clear out the add box
    $('input.add_options_box').tokenInput('clear');
  };

  // removes an option from the view
  klass.prototype.remove_option = function(link) { var self = this;
    // lookup optioning object remove from option set
    self.option_set.remove_optioning(link.closest('div.inner').data('optioning'));

    // remove from view
    link.closest('li').remove();

    // dirty!
    self.dirty = true;
  };

  // shows the edit dialog
  klass.prototype.edit_option = function(link) { var self = this;
    // get the optioning and save it as an instance var as we will need to access it
    // when the modal gets closed
    self.active_optioning = link.closest('div.inner').data('optioning');

    // clear the text boxes
    ELMO.app.params.mission_locales.forEach(function(locale){
      $('div.edit_option_form input#name_' + locale).val("");
    });

    // hide the in_use warning
    $('div.edit_option_form div.option_in_use_name_change_warning').hide();

    // then populate text boxes
    for (var locale in self.active_optioning.option.name_translations)
      $('div.edit_option_form input#name_' + locale).val(self.active_optioning.option.name_translations[locale]);

    // show the modal
    $('#edit-option-set').modal('show');

    // show the form
    $('div.edit_option_form').show();

    // show the in_use warning if appopriate
    if (self.active_optioning.option.in_use) $('div.edit_option_form div.option_in_use_name_change_warning').show();
  };

  // saves entered translations to data model
  klass.prototype.save_option = function() { var self = this;

    $('div.edit_option_form input[type=text]').each(function(){
      self.active_optioning.update_translation({field: 'name', locale: $(this).data('locale'), value: $(this).val()});
    });

    // dirty!
    self.dirty = true;

    // re-render the option in the view
    var old_div = self.active_optioning.div;
    var new_div = self.render_option(self.active_optioning);
    old_div.replaceWith(new_div);

    // done with this optioning
    self.active_optioning = null;

    $('#edit-option-set').modal('hide');
  };

  // write the data model to the form as hidden tags so that the data will be included in the submission
  klass.prototype.form_submitted = function() { var self = this;
    // save the name in the data model
    self.option_set.name = $('#option_set_name').val();

    var form = $('form.option_set_form');
    self.option_set.optionings.forEach(function(optioning, idx){
      if (optioning.id)
        self.add_form_field('option_set[optionings_attributes][' + idx + '][id]', optioning.id);
      self.add_form_field('option_set[optionings_attributes][' + idx + '][rank]', optioning.div.closest('li').index() + 1);

      if (optioning.id || !optioning.option.id) {
        self.add_form_field('option_set[optionings_attributes][' + idx + '][option_attributes][id]', optioning.option.id);
        for (var locale in optioning.option.name_translations)
          self.add_form_field('option_set[optionings_attributes][' + idx + '][option_attributes][name_' + locale + ']', optioning.option.name_translations[locale]);
      } else {
        self.add_form_field('option_set[optionings_attributes][' + idx + '][option_id]', optioning.option.id);
      }
    });

    // add removed optionings
    self.option_set.removed_optionings.forEach(function(optioning, idx){
      self.add_form_field('option_set[optionings_attributes][_' + idx + '][id]', optioning.id);
      self.add_form_field('option_set[optionings_attributes][_' + idx + '][_destroy]', 'true');
    });

    // cancel the dirty flag so no warning
    self.dirty = false;

    // if the form is in ajax mode, submit via ajax
    if (self.params.ajax_mode) {
      $.ajax({
        url: $('form.option_set_form').attr('action'),
        method: 'POST',
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

    } else {
      // if not in ajax mode, just return true and let form submit normally
      return true;
    }
  };

  // adds a hidden form field with the given name and value
  klass.prototype.add_form_field = function(name, value) { var self = this;
    $('form.option_set_form').append($('<input>').attr('type', 'hidden').attr('name', name).attr('value', value));
  };

})(ELMO.Views);
