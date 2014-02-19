// ELMO.Views.OptionLevelsField
//
// View model for the options area of the option sets form.
(function(ns, klass) {

  // constructor
  ns.OptionLevelsField = klass = function(params) { var self = this;
    self.params = params;
    self.option_levels = params.option_levels;

    // create the draggable list to hold the options
    self.list = new ELMO.Views.DraggableList({
      items: params.option_levels,
      wrapper: params.wrapper,
      modal: params.modal,
      form_mode: params.form_mode,
      can_reorder: self.params.can_reorder,
      can_remove: self.params.can_remove,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link,
      modal_titles: {
        new: I18n.t('option_set.new_option_level'),
        edit: I18n.t('option_set.edit_option_level')
      }
    });

    // handler for when items are added to list
    self.list.on('item_added', function(item){
      self.option_levels.add(item);
    });
  };

  // initiates add level process
  klass.prototype.add = function() { var self = this;
    self.list.new_item(new ELMO.Models.NamedItem());
  };

  klass.prototype.show = function(yn) { var self = this;
    $('.form_field[data-field-name=option_levels')[yn ? 'show' : 'hide']();
  };

})(ELMO.Views);
