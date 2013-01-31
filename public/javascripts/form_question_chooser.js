// ELMO.FormQuestionChooser
(function(ns, klass) {
  
  // constructor
  ns.FormQuestionChooser = klass = function() {
    
    // if there is no question list (b/c there are no questions) we can just show the form and hide the 'return' link
    if ($("div.question_list").size() == 0) {
      $("div.question_form").show();
      $("a.question_list").hide();
    
    // otherwise we have to hook up both links
    } else {
      // hookup the add questions link
      $("a.create_question").click(function(){
        $("div.question_list").hide();
        $("div.question_form").show();
        return false;
      });
    
      // hookup the return link
      $("a.question_list").click(function(){
        $("div.question_list").show();
        $("div.question_form").hide();
        return false;
      });
    }
  }

}(ELMO));