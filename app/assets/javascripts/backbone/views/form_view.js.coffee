# Holds code of general use in Backbone views for forms.
class ELMO.Views.FormView extends ELMO.Views.ApplicationView

  # Fetches a form value from a form built with ElmoFormBuilder.
  # Works even for a show view by using the .ro-val tag.
  form_value: (klass, attrib) ->
    # Check for a tag with .ro-val inside the .form-field wrapper.
    # If we find it, we are done. Else we expect the actual form (e.g. input, select) element to
    # have a predictable ID and to work with the `val` jquery method. If it doesn't this method won't work.
    id = "#{klass}_#{attrib}"
    ro_val = @$(".form-field.#{id} .ro-val")
    if ro_val.length
      ro_val.data('val')
    else
      @$("##{id}").val()

  # Shows/hides the form field with the given name.
  showField: (name, showHide, options = {}) ->
    comparison = if options.prefix then '^=' else '='
    display = if showHide then "flex" else "none"
    @$(".form-field[data-field-name#{comparison}\"#{name}\"]").css("display", display)
