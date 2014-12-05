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

    // set tally type/report type, if report type is a tally report
    if (this.attribs.type == 'Report::AnswerTallyReport') {
      this.attribs.type = 'Report::TallyReport';
      this.attribs.tally_type = 'Answer';
    } else if (this.attribs.type == 'Report::ResponseTallyReport') {
      this.attribs.type = 'Report::TallyReport';
      this.attribs.tally_type = 'Response';
    }

    this.attribs.disaggregate = this.attribs.disagg_question_id != null;
  }

  klass.prototype.clone = function() {
    var new_attribs = $.extend(true, {}, this.attribs);
    return new klass(new_attribs, this.menus);
  }

  klass.prototype.has_run = function() {
    return !this.attribs.new_record;
  }

  // checks if the report has errors or not
  klass.prototype.has_errors = function() {
    // Rails errors converts to json as {} if no errors
    return !this.attribs.errors || Object.keys(this.attribs.errors).length > 0;
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

    var omnibus_calc_type = "Report::" + _this.attribs.omnibus_calculation.capitalize().underscore_to_camel() + "Calculation"

    if (this.attribs.tally_type != "Answer") return;

    // calculations to empty array if not exist
    this.attribs.calculations_attributes = this.attribs.calculations_attributes || [];

    // do a match thing: if found, leave; if not found, set _destroy; if new, create new with no id
    Sassafras.Utils.match_lists(
      {list: this.attribs.calculations_attributes, comparator: function(c){ return c.question1_id.toString() + ":" + c.type; }},
      {list: qids, comparator: function(id){ return id + ":" + omnibus_calc_type; }},
      function(current_calc, new_id) {
        // if new_id has no accompanying current_calc, create a new one
        if (current_calc == null)
          _this.attribs.calculations_attributes.push({question1_id: new_id, type: omnibus_calc_type});

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
    return this.attribs.aggregation_name || I18n.t("report/report.tally");
  }

  // returns a filter string fragment for the selected form ids
  klass.prototype.form_filter_str = function() {
    if (this.attribs.form_ids == "ALL")
      return null;
    else
      return "form:(\"" + this.menus.form.get_names(this.attribs.form_ids).join("\"|\"") + "\")";
  }

  klass.prototype.extract_form_ids_from_filter_str = function() {
    var m;
    if (this.attribs.filter && (m = this.attribs.filter.match(/^form:\((.*)\)$/))) {
      this.attribs.filter = "";

      // split name str and strip quotes
      var names = m[1].split("|");
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
    $(["type", "name", "form_id", "display_type", "percent_type", "bar_style", "question_order", "group_by_tag",
        "question_labels", "text_responses", "calculations_attributes", "disagg_question_id"]).each(function(){
      to_serialize[this] = (typeof(self.attribs[this]) == "undefined" || self.attribs[this] == null) ? "" : self.attribs[this];
    });

    // calc attribs must be an array
    if (to_serialize['calculations_attributes'] == '') to_serialize['calculations_attributes'] = [];

    // adjust type if tally report
    if (to_serialize['type'] == 'Report::TallyReport')
      to_serialize['type'] = 'Report::' + this.attribs.tally_type + 'TallyReport';

    if (this.attribs.tally_type == "Answer")
      to_serialize.option_set_choices_attributes = self.attribs.option_set_choices_attributes;

    to_serialize.filter = this.form_filter_str();

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
      this.errors.add("type", I18n.t("activerecord.errors.models.report/report.attributes.type.blank"));

    // form_id, text_responses, and question_order should be non-null if type is std form report
    if (this.attribs.type == 'Report::StandardFormReport' && !this.attribs.form_id)
      this.errors.add("form_id", I18n.t("activerecord.errors.models.report/report.attributes.form_id.blank"));
    if (this.attribs.type == 'Report::StandardFormReport' && !this.attribs.question_order)
      this.errors.add("question_order", I18n.t("activerecord.errors.models.report/report.attributes.question_order.blank"));
    if (this.attribs.type == 'Report::StandardFormReport' && !this.attribs.text_responses)
      this.errors.add("text_responses", I18n.t("activerecord.errors.models.report/report.attributes.text_responses.blank"));

    // tally type should be non-null if type is tallyreport
    if (this.attribs.type == 'Report::TallyReport' && !this.attribs.tally_type)
      this.errors.add("tally_type", I18n.t("activerecord.errors.models.report/report.attributes.tally_type.blank"));

    // title
    if (!this.attribs.name.match(/\w+/))
      this.errors.add("name", I18n.t("activerecord.errors.models.report/report.attributes.name.blank"));

    // question/option_set
    if (this.attribs.tally_type == "Answer"
      && this.count_not_to_be_destroyed(this.attribs.calculations_attributes) == 0
      && this.count_not_to_be_destroyed(this.attribs.option_set_choices_attributes) == 0)
        this.errors.add("questions", I18n.t("activerecord.errors.models.report/report.attributes.questions.blank"));

    // fields
    if (this.attribs.type == "Report::ListReport" && this.count_not_to_be_destroyed(this.attribs.calculations_attributes) == 0)
      this.errors.add("fields", I18n.t("activerecord.errors.models.report/report.attributes.fields.blank"));

    // report is valid if errors are empty
    return this.errors.empty();
  }

}(ELMO.Report));
