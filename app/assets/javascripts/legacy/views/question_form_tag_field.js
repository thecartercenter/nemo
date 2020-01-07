// ELMO.Views.QuestionFormTagField
//
// View model for Tags field on Question form
(function (ns, klass) {
  // constructor
  ns.QuestionFormTagField = klass = function (params) {
    const self = this;
    self.params = params;
    self.items = [];
    self.silent = false;
    self.input = $("input[id$='_tag_ids']");

    // Using an ends with selector because the id is different on question and questioning forms
    self.input.tokenInput(`${params.suggest_tags_path}.json`, {
      theme: 'elmo',
      jsonContainer: 'tags',
      hintText: I18n.t('tag.type_to_add_new'),
      noResultsText: I18n.t('tag.none_found'),
      searchingText: I18n.t('tag.searching'),
      resultsFormatter: self.format_token_result,
      tokenFormatter: self.format_token,
      prePopulate: params.question_tags,
      onAdd(item) {
        if (!self.silent) {
          self.add_tag(item, params.mission_id);
        }
      },
      onDelete(item) {
        if (!self.silent) {
          self.remove_tag(item);
        }
      },

      // Prevent enter press from submitting form.
      onEnter() { return false; },
    });

    // Add hidden inputs for any unsaved tags.
    params.question_tags.forEach((t) => {
      if (!t.id) {
        self.add_tag(t, params.mission_id);
      } else {
        self.items.push(t);
      }
    });
  };

  // If tag doesn't already exist, append hidden inputs to add it via nested attributes
  klass.prototype.add_tag = function (item, missionId) {
    let form; let
      inputNamePrefix;

    // Which form are we on?
    const rand = Math.floor(Math.random() * 999999999);
    if ($('.question_form').length) {
      form = $('.question_form');
      inputNamePrefix = `question[tags_attributes][${rand}]`;
    } else if ($('.questioning_form').length) {
      form = $('.questioning_form');
      inputNamePrefix = `questioning[question_attributes][tags_attributes][${rand}]`;
    }

    if (item.id === null) {
      // Strip trailing whitespace
      this.silent = true;
      this.input.tokenInput('remove', item);
      item.name = item.name.trim();
      this.input.tokenInput('add', item);
      this.silent = false;
    }

    const exists = _.find(this.items, (tag) => {
      if (item.id) {
        return item.id === tag.id;
      }
      return item.name.trim() === tag.name;
    });

    if (exists) {
      // De-duplicate
      this.silent = true;
      this.input.tokenInput('remove', item);
      this.input.tokenInput('add', item);
      this.silent = false;
      return;
    }

    // If new item (null id)
    if (item.id === null) {
      form.append(
        `<input type="hidden" data-new-tag="${item.name}" name="${inputNamePrefix
        }[name]" value="${item.name}">`
          + `<input type="hidden" data-new-tag="${item.name}" name="${inputNamePrefix
          }[mission_id]" value="${missionId}">`,
      );
    }

    this.items.push(item);
  };

  // If previously added new tag input, remove it
  klass.prototype.remove_tag = function (item) {
    const index = _.findIndex(this.items, (tag) => {
      return tag.id === item.id || tag.name === item.name;
    });

    if (index !== -1) {
      this.items.splice(index, 1);
    }

    if (item.id == null && $.inArray(item, $("input.form-control[id$='_tag_ids']").tokenInput('get')) == -1) {
      $(`input[data-new-tag="${item.name}"]`).remove();
    }
  };

  // returns the html to insert in the token input result list
  klass.prototype.format_token_result = function (item) {
    // if this is the new placeholder, add a string about that
    if (item.id == null) {
      return `<li><i class="fa fa-fw fa-plus-circle"></i> ${item.name
      } <span class="details create_new">[${I18n.t('tag.new_tag')}]</span>` + '</li>';
    }
    return `<li><i class="fa fa-fw"></i> ${item.name}</li>`;
  };

  // returns the html to display the tokens in the input field
  klass.prototype.format_token = function (item) {
    // if this is a new tag, add an icon
    if (item.id == null) {
      return `<li><i class="fa fa-plus-circle"></i> ${item.name}</li>`;
    }
    return `<li>${item.name}</li>`;
  };
}(ELMO.Views));
