// ELMO.Report.Report
(function(ns, klass) {
  
  // constructor
  ns.Report = klass = function(attribs, menus) {
    this.attribs = attribs;
    this.menus = menus;
  }
  
  // called when data first received
  klass.prototype.prepare = function() {
    this.extract_form_ids_from_filter_str();
  }
  
  klass.prototype.clone = function() {
    var new_attribs = $.extend(true, {}, this.attribs);
    return new klass(new_attribs, this.menus);
  }
  
  klass.prototype.has_run = function() {
    return !this.attribs.new_record;
  }
  
  // checks if the report has data or not
  klass.prototype.no_data = function() {
    return this.attribs.data.rows.length == 0;
  }

  // checks if the report has errors or not
  klass.prototype.has_errors = function() {
    return !!this.attribs.errors;
  }
  
  // scans through all calculations and returns an array of question ids
  klass.prototype.get_calculation_question_ids = function() {
    var qids = [];
    if (this.attribs.calculations_attributes)
      for (var i = 0; i < this.attribs.calculations_attributes.length; i++)
        if (this.attribs.calculations_attributes[i].question1_id)
          qids.push(this.attribs.calculations_attributes[i].question1_id);
    return qids;
  }
  
  klass.prototype.set_calculations_by_question_ids = function(qids) {
    var _this = this;
    
    if (this.attribs.type != "Report::QuestionAnswerTallyReport") return;
    
    // calculations to empty array if not exist
    this.attribs.calculations_attributes = this.attribs.calculations_attributes || [];
    
    // do a match thing: if found, leave; if not found, set _destroy; if new, create new with no id
    Sassafras.Utils.match_lists(
      {list: this.attribs.calculations_attributes, comparator: function(c){ return c.question1_id.toString() + ":" + c.type; }}, 
      {list: qids, comparator: function(id){ return id + ":" + _this.attribs.omnibus_calculation; }},
      function(current_calc, new_id) {
        // if new_id has no accompanying current_calc, create a new one
        if (current_calc == null)
          _this.attribs.calculations_attributes.push({question1_id: new_id, type: _this.attribs.omnibus_calculation});
      
        // if current_calc is not in the given qids, mark it for destruction
        else if (new_id == null)
          current_calc._destroy = "true";
          
        // if both found, make sure the current is not marked for destruction
        else if (current_calc._destroy)
          delete current_calc._destroy;
      }
    )
  }
  
  klass.prototype.get_option_set_ids = function() { var self = this;
    var osids = [];
    // gather id's from the option_set_choices array
    if (self.attribs.option_set_choices_attributes)
      $(self.attribs.option_set_choices_attributes).each(function(){ osids.push(this.option_set_id); });
    return osids;
  }
  
  klass.prototype.set_option_set_ids = function(ids) { var self = this;
    // option_set_choices to empty array if not exist
    self.attribs.option_set_choices_attributes = self.attribs.option_set_choices_attributes || [];
    
    // do a match thing: if found, leave; if not found, set _destroy; if new, create new with no id
    Sassafras.Utils.match_lists(
      {list: self.attribs.option_set_choices_attributes, comparator: function(osc){ return osc.option_set_id; }}, 
      {list: ids},
      function(current_osc, new_id) {
        // if new_id has no accompanying osc, create a new one
        if (current_osc == null)
          self.attribs.option_set_choices_attributes.push({option_set_id: new_id});
      
        // if current_osc is not in the given ids, mark it for destruction
        else if (new_id == null)
          current_osc._destroy = "true";
          
        // if both found, make sure the current_osc is not marked for destruction
        else if (current_osc._destroy)
          delete current_osc._destroy;
      }
    )
  }
  
  klass.prototype.aggregation = function() {
    return this.attribs.aggregation_name || "Tally";
  }
  
  // returns a filter string fragment for the selected form ids
  klass.prototype.form_filter_str = function() {
    if (this.attribs.form_ids == "ALL")
      return null;
    else
      return "form:\"" + this.menus.form.get_names(this.attribs.form_ids).join("\",\"") + "\"";
  }
  
  klass.prototype.extract_form_ids_from_filter_str = function() {
    var m;
    if (m = this.attribs.filter_str.match(/^\(form:(.*)\)( and \((.+)\))?/)) {
      this.attribs.filter_str = m[3] || "";
      
      // split name str and strip quotes
      var names = m[1].split(",");
      $(names).each(function(i){ names[i] = names[i].substring(1, names[i].length - 1); });
      
      // get ids from form menu
      this.attribs.form_ids = this.menus.form.get_ids_from_names(names);
    } else {
      this.attribs.form_ids = "ALL";
    }
  }
  
  // ensures calculation ranks match array indices
  klass.prototype.fix_calculation_ranks = function() {
    if (this.attribs.calculations_attributes)
      for (var i = 0; i < this.attribs.calculations_attributes.length; i++)
        // don't count 'to be destroyed' calculations
        if (this.attribs.calculations_attributes[i].type)
          this.attribs.calculations_attributes[i].rank = i + 1;
  }
  
  klass.prototype.to_hash = function() { var self = this;
    // fix calculation ranks
    self.fix_calculation_ranks();

    var to_serialize = {}
    $(["type", "name", "display_type", "percent_type", "bar_style", "question_labels", "calculations_attributes"]).each(function(){
      to_serialize[this] = (typeof(self.attribs[this]) == "undefined" || self.attribs[this] == null) ? "" : self.attribs[this];
    });
    
    if (this.attribs.type == "Report::QuestionAnswerTallyReport")
      to_serialize.option_set_choices_attributes = self.attribs.option_set_choices_attributes;
    
    // filter params
    to_serialize.filter_attributes = {}
    to_serialize.filter_attributes.class_name = "Response"

    // include the form id spec in the filter string
    var filter_clauses = []
    var form_str = this.form_filter_str();
    if (form_str) filter_clauses.push("(" + form_str + ")");
    if (this.attribs.filter_str.length > 0) filter_clauses.push("(" + this.attribs.filter_str + ")");
    
    to_serialize.filter_attributes.str = filter_clauses.join(" and ")
    
    return to_serialize;
  }
  
  klass.prototype.calculation_by_rank = function(rank) {
    if (!this.attribs.calculations_attributes)
      return null;
      
    for (var i = 0; i < this.attribs.calculations_attributes.length; i++)
      if (this.attribs.calculations_attributes[i].rank == rank)
        return this.attribs.calculations_attributes[i];
    return null;
  }
  
  // counts the number of objects in the given array that don't have _destroy = true
  klass.prototype.count_not_to_be_destroyed = function(arr) {
    var count = 0;
    $(arr).each(function(){ if (!this._destroy) count++; });
    return count;
  }
  
  // checks that all attributes are valid. 
  // returns true if valid.
  // returns false if invalid and sets validation errors.
  klass.prototype.validate = function() {
    this.errors = new ns.Errors();

    // type
    if (!this.attribs.type)
      this.errors.add("type", "You must choose a report type.");

    // title
    if (!this.attribs.name.match(/\w+/))
      this.errors.add("name", "You must enter a report title.");

    // question/option_set
    if (this.attribs.type == "Report::QuestionAnswerTallyReport" 
      && this.count_not_to_be_destroyed(this.attribs.calculations_attributes) == 0 
      && this.count_not_to_be_destroyed(this.attribs.option_set_choices_attributes) == 0)
        this.errors.add("questions", "You must choose at least one question or one option set.");
      
    // fields
    if (this.attribs.type == "Report::ListReport" && this.count_not_to_be_destroyed(this.attribs.calculations_attributes) == 0)
      this.errors.add("fields", "You must choose at least one question or attribute.");
    
    // report is valid if errors are empty
    return this.errors.empty();
  }
  
}(ELMO.Report));