// a select box that shows only questions that can be used to disaggregate the present form
// ELMO.Report.DisaggQuestionSelector
(function(ns, klass) {
  
  // constructor
  ns.DisaggQuestionSelector = klass = function(question_menu) {
    this.question_menu = question_menu;
    this.visible = true;
    
    // create the select object
    this.field = new ELMO.Control.Select({
      el: $("select#disagg_qing"),
      prompt: true,
      objs: [],
      id_key: 'id',
      txt_key: 'code'
    });
  }

  // called when the form_id or disagg_question_id has been updated, thus necessitating a change to the available options
  klass.prototype.update = function(report) {
    this.report = report;

    console.log(report.attribs.form_id);
    
    // get the appropriate questions
    var questions = this.question_menu.filter({form_ids: [report.attribs.form_id], question_types: ['select_one']});

    // update our select control with the new questions
    this.field.update_objs(questions);

    // update the select control's value        
    this.field.update(report.attribs.disagg_question_id);
  }
  
  // gets the current field value
  klass.prototype.get = function() {
    return this.field.get();
  }
  
}(ELMO.Report));