// ELMO.Report.FieldSelector
(function(ns, klass) {
  
  // constructor
  ns.FieldSelector = klass = function(cont, menus) {
    this.cont = cont;
    this.menus = menus;
    
    // create the select object
    this.field = new ELMO.Control.Select({
      el: this.cont.find("select.field"),
      grouped: true,
      prompt: true
    });
  }

  klass.prototype.update = function(report, rank) {
    this.report = report;
    this.rank = rank;
    this.calc = report.calculation_by_rank(rank);
    
    this.field.update_objs([
      {
        label: "Attributes",
        objs: this.menus.attrib.objs,
        id_key: function(obj) { return "attrib1_name:" + obj.name; },
        txt_key: "title"
      },{
        label: "Questions",
        objs: this.menus.question.for_forms_and_calc_type(this.report.attribs.form_ids, "Report::IdentityCalculation"),
        id_key: function(obj) { return "question1_id:" + obj.id; },
        txt_key: "code"
      }
    ]);
    
    var key;
    if (!this.calc)
      key = "";
    else if (this.calc.question1_id)
      key = "question1_id:" + this.calc.question1_id;
    else
      key = "attrib1_name:" + this.calc.attrib1_name;
    
    this.field.update(key);
  }
  
  klass.prototype.get = function() {
    var field_val = this.field.get();
    var field_params = {};

    if (this.calc && this.calc.id)
      field_params.id = this.calc.id;
    
    if (!field_val) {
      if (field_params.id) field_params._destroy = true;
    } else {
      field_val = field_val.split(":");
      
      // set both values blank to start
      field_params.question1_id = "";
      field_params.attrib1_name = "";
      
      // convert to integer if necessary
      if (field_val[0] == "question1_id") 
        field_val[1] = parseInt(field_val[1]);
      
      // build the attrib obj
      field_params.type = "Report::IdentityCalculation";
      field_params.rank = this.rank;
      field_params[field_val[0]] = field_val[1];
    }

    return field_params;
  }

}(ELMO.Report));