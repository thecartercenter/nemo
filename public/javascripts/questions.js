function show_hide_option_set(question_type) {
  show = question_type.match(/^Select/)
  $('option_set')[show ? 'show' : 'hide']()
  $('option_set_not_applicable')[!show ? 'show' : 'hide']()
  if (!show) $('option_set').selectedIndex = 0
}