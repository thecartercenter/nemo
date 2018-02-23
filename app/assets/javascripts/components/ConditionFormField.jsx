class ConditionFormField extends React.Component {
  constructor(props) {
    super();
    this.getFieldData = this.getFieldData.bind(this);
    this.updateFieldData = this.updateFieldData.bind(this);
    this.formatRefQingOptions = this.formatRefQingOptions.bind(this);
    this.buildUrl = this.buildUrl.bind(this);
    this.buildValueProps = this.buildValueProps.bind(this);
    this.removeCondition = this.removeCondition.bind(this);
    this.state = props;
  }

  updateFieldData(refQingId) {
    this.getFieldData(refQingId);
  }

  getFieldData(refQingId) {
    ELMO.app.loading(true);
    let self = this;
    let url = this.buildUrl(refQingId);
    $.ajax(url)
      .done(function(response) {
        // Need to put this before we set state because setting state may trigger a new one.
        ELMO.app.loading(false);

        // We set option node ID to null since the new ref_qing may have a new option set.
        self.setState(Object.assign(response, {option_node_id: null}));
      })
      .fail(function(jqXHR, exception) {
        ELMO.app.loading(false);
        console.log(exception);
      });
  }

  buildUrl(refQingId) {
    let url = `${ELMO.app.url_builder.build("form-items", "condition-form")}?`;
    url += `condition_id=${this.state.id || ""}&ref_qing_id=${refQingId}&form_id=${this.state.form_id}`;
    if (this.state.conditionable_id) {
      url += "&conditionable_id=" + this.state.conditionable_id;
      url += "&conditionable_type=" + this.state.conditionable_type;
    }
    return url;
  }

  formatRefQingOptions(reference_qing_options) {
    return reference_qing_options.map(function(o) {
      return {id: o.id, name: `${o.full_dotted_rank}. ${o.code}`, key: o.id};
    });
  }

  removeCondition() {
    this.setState({remove: true});
  }

  buildValueProps(name_prefix, id_prefix) {
    if (this.state.option_set_id !== null) {
      return {
        type: "cascading_select",
        name_prefix: name_prefix,
        for: `${id_prefix}_value`, // Not a mistake; the for is for value; the others are for selects
        id: `${id_prefix}_option_node_ids_`,
        key: `${id_prefix}_option_node_ids_`,
        option_set_id: this.state.option_set_id,
        option_node_id: this.state.option_node_id,
      };
    } else {
      return {
        type: "text",
        name: `${name_prefix}[value]`,
        for: `${id_prefix}_value`,
        id: `${id_prefix}_value`,
        key: `${id_prefix}_value`,
        value: this.state.value ? this.state.value : "",
      };
    }
  }

  render() {
    let name_prefix = this.state.name_prefix + `[${this.state.index}]`;
    let id_prefix = name_prefix.replace(/[\[\]]/g, "_");
    let id_field_props = {
      type: "hidden",
      name: `${name_prefix}[id]`,
      id: `${id_prefix}_id`,
      key: `${id_prefix}_id`,
      value: this.state.id ? this.state.id : ""
    };
    let ref_qing_field_props = {
      name: `${name_prefix}[ref_qing_id]`,
      key: `${id_prefix}_ref_qing_id`,
      value: this.state.ref_qing_id ? this.state.ref_qing_id : "",
      options: this.formatRefQingOptions(this.state.refable_qings),
      prompt: I18n.t("condition.ref_qing_prompt"),
      changeFunc: this.updateFieldData
    };
    let operator_field_props = {
      name: `${name_prefix}[op]`,
      key: `${id_prefix}_op`,
      value: this.state.op ? this.state.op : "",
      options: this.state.operator_options,
      include_blank: false
    };
    let destroy_field_props = {
      type: "hidden",
      name: `${name_prefix}[_destroy]`,
      id: `${id_prefix}__destroy`,
      key: `${id_prefix}__destroy`,
      value: this.shouldDestroy() ? "1" : "0",
    };
    let value_field_props = this.buildValueProps(name_prefix, id_prefix);

    return (
      <div
        className="condition-fields"
        style={{display: this.shouldDestroy() ? "none" : ""}}>
        <input {...id_field_props} />
        <input {...destroy_field_props} />
        <FormSelect {...ref_qing_field_props} />
        <FormSelect {...operator_field_props} />
        <div className="condition-value">
          <FormField {...value_field_props} />
        </div>
        <div className="condition-remove">
          <a onClick={this.removeCondition}>
            <i className="fa fa-close" />
          </a>
        </div>
      </div>
    );
  }

  shouldDestroy() {
    return this.state.remove || this.props.hide;
  }
}
