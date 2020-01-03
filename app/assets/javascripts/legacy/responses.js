// setup handler for 'create response'
$(document).ready(() => {
  $(document).on('click', 'a.create_response', () => {
    $('#form_chooser').show();
    return false;
  });
});
