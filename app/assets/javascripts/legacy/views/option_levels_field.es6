// ELMO.Views.OptionLevelsField
//
// View model for the options area of the option sets form.
(function (ns, klass) {
  // constructor
  ns.OptionLevelsField = klass = function (params) {
    const self = this;
    self.params = params;

    // create the draggable list to hold the options
    self.list = new ELMO.Views.DraggableList({
      items: params.option_levels || [],
      item_class: ELMO.Models.NamedItem,
      wrapper: params.wrapper,
      modal: params.modal,
      options_levels_read_only: params.options_levels_read_only,
      multilevel: false,
      can_reorder: self.params.can_reorder,
      can_remove: self.params.can_remove,
      edit_link: self.params.edit_link,
      remove_link: self.params.remove_link,
      modal_titles: {
        new: I18n.t('option_set.new_option_level'),
        edit: I18n.t('option_set.edit_option_level'),
      },
    });

    // No nesting for option levels
    self.list.allow_nesting(false);
  };

  // initiates add level process
  klass.prototype.add = function () {
    const self = this;
    self.list.new_item(new ELMO.Models.NamedItem());
  };

  klass.prototype.show = function (yn) {
    const self = this;
    // select option level and corresponding hint
    const multiOptionField = $('.form-field[data-field-name=option_levels]');
    multiOptionField.css('display', yn ? 'flex' : 'none');
  };
}(ELMO.Views));
