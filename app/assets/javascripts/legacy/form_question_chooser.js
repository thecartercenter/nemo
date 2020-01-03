// ELMO.FormQuestionChooser
(function (ns, klass) {
  // constructor
  ns.FormQuestionChooser = klass = function () {
    // if there is no question list (b/c there are no questions) we can just show the form and hide the 'return' link
    if ($('div.question_list').size() == 0) {
      $('div.question_form').show();
      $('a.question_list').hide();

    // otherwise we have to hook up both links
    } else {
      // hookup the add questions link
      $('a.create_question').click(() => {
        $('div.question_list').hide();
        $('div.question_form').show();
        return false;
      });

      // hookup the return link
      $('a.question_list').click(() => {
        $('div.question_list').show();
        $('div.question_form').hide();
        return false;
      });
    }

    // make a click anywhere on question list toggle checkbox
    $('div.question_list tbody.index_table_body tr').on('click', (e) => {
      if (e.target.tagName == 'DIV' || e.target.tagName == 'TD') $(e.currentTarget).find('input[type=checkbox]').first().trigger('click');
    });
  };
}(ELMO));
