// ELMO.Views.QuestionFormTagField
//
// View model for Tags field on Question form
(function(ns, klass) {

  // constructor
  ns.QuestionFormTagField = klass = function(params) { var self = this;
    self.params = params;

    // Using an ends with selector because the id is different on question and questioning forms
    $("input[id$='_tag_ids']").tokenInput(params.suggest_tags_path + '.json', {
      theme: 'elmo',
      jsonContainer: 'tags',
      hintText: I18n.t('tag.type_to_add_new'),
      noResultsText: I18n.t('tag.none_found'),
      searchingText: I18n.t('tag.searching'),
      resultsFormatter: self.format_token_result,
      tokenFormatter: self.format_token,
      prePopulate: params.question_tags,
      onAdd: function(item) { self.add_tag(item, params.mission_id) },
      onDelete: self.remove_tag,

      // Prevent enter press from submitting form.
      onEnter: function() { return false; }
    });
  };

  // If tag doesn't already exist, append hidden inputs to add it via nested attributes
  klass.prototype.add_tag = function(item, mission_id) {
    var form, input_name_prefix, selector;
    // Which form are we on?
    if ($('.question_form').length) {
      form = $('.question_form');
      input_name_prefix = 'question[tags_attributes][]';
    } else if ($('.questioning_form').length) {
      form = $('.questioning_form');
      input_name_prefix = 'questioning[question_attributes][tags_attributes][]';
    }
    selector = 'input[name="'+input_name_prefix+'[name]"][value="'+item.name+'"]';
    // if new item (null id) and hasn't already been added to this page
    if (item.id == null && $(selector).length == 0) {
      form.append(
        '<input type="hidden" name="'+input_name_prefix+'[name]" value="'+item.name+'">' +
        '<input type="hidden" name="'+input_name_prefix+'[mission_id]" value="'+mission_id+'">'
      );
    }
  };

  // If previously added new tag input, remove it
  klass.prototype.remove_tag = function(item) {
    if (item.id == null && $.inArray(item, $("input.form-control[id$='_tag_ids']").tokenInput('get')) == -1) {
      $("input[name$='[tags_attributes][][name]'][value='"+item.name+"']").remove();
    }
  };

  // returns the html to insert in the token input result list
  klass.prototype.format_token_result = function(item) {
    // if this is the new placeholder, add a string about that
    if (item.id == null) {
      return '<li><i class="fa fa-fw fa-plus-circle"></i> ' + item.name +
          ' <span class="details create_new">[' + I18n.t('tag.new_tag') + ']</span>' + '</li>';
    } else {
      return '<li><i class="fa fa-fw"></i> ' + item.name + '</li>';
    }
  };

  // returns the html to display the tokens in the input field
  klass.prototype.format_token = function(item) {
    // if this is a new tag, add an icon
    if (item.id == null) {
      return '<li><i class="fa fa-plus-circle"></i> ' + item.name + '</li>';
    } else {
      return '<li>' + item.name + '</li>';
    }
  };

}(ELMO.Views));
