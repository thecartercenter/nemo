// setup handler for 'create response'
$(document).ready(function(){
  $(document).on("click", "a.create_response", function(){
    $('#form_chooser').show();
    return false;
  });
});
