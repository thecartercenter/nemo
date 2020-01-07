/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// Holds code of general use in Backbone views for forms.
ELMO.Views.FormView = class FormView extends ELMO.Views.ApplicationView {
  // Fetches a form value from a form built with ElmoFormBuilder.
  // Works even for a show view by using the .ro-val tag.
  form_value(klass, attrib) {
    // Check for a tag with .ro-val inside the .form-field wrapper.
    // If we find it, we are done. Else we expect the actual form (e.g. input, select) element to
    // have a predictable ID and to work with the `val` jquery method. If it doesn't this method won't work.
    const id = `${klass}_${attrib}`;
    const ro_val = this.$(`.form-field.${id} .ro-val`);
    if (ro_val.length) {
      return ro_val.data('val');
    }
    return this.$(`#${id}`).val();
  }

  // Shows/hides the form field with the given name.
  showField(name, showHide, options) {
    if (options == null) { options = {}; }
    const comparison = options.prefix ? '^=' : '=';
    const display = showHide ? 'flex' : 'none';
    return this.$(`.form-field[data-field-name${comparison}\"${name}\"]`).css('display', display);
  }
};
