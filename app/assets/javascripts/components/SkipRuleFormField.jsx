class SkipRuleFormField extends React.Component {
  constructor(props) {
    super();

    let dest_item_id_or_end = props.destination == "end" ? "end" : props.dest_item_id;
    this.state = Object.assign({}, props, {dest_item_id_or_end: dest_item_id_or_end});

    this.destinationOptionChanged = this.destinationOptionChanged.bind(this);
    this.skipIfChanged = this.skipIfChanged.bind(this);
    this.removeRule = this.removeRule.bind(this);
  }

  destinationOptionChanged(value) {
    this.setState({
      dest_item_id_or_end: value,
      destination: value == "end" ? "end" : "item",
      dest_item_id: value == "end" ? null : value
    });
  }

  skipIfChanged(event) {
    this.setState({
      skip_if: event.target.value
    });
  }

  removeRule() {
    this.setState({remove: true});
  }

  formatTargetItemOptions(items) {
    return items.map(function(o) {
      return {
        id: o.id,
        key: o.id,
        name: I18n.t("skip_rule.skip_to_item", {label: `${o.full_dotted_rank}. ${o.code}`})
      };
    }).concat([{id: "end", name: I18n.t("form_item.end_of_form"), key: "end"}]);
  }

  render() {
    let name_prefix = this.props.name_prefix;

    let id_field_props = {
      type: "hidden",
      name: `${name_prefix}[id]`,
      value: this.state.id || ""
    };

    let destination_props = {
      value: this.state.dest_item_id_or_end || "",
      prompt: I18n.t("skip_rule.dest_prompt"),
      options: this.formatTargetItemOptions(this.state.later_items),
      changeFunc: this.destinationOptionChanged
    };

    let skip_if_props = {
      name: `${name_prefix}[skip_if]`,
      value: this.state.skip_if,
      className: "form-control",
      onChange: this.skipIfChanged
    };

    let condition_set_props = {
      conditions: this.state.conditions,
      conditionable_id: this.state.id,
      conditionable_type: "SkipRule",
      refable_qings: this.state.refable_qings,
      name_prefix: `${name_prefix}[conditions_attributes]`,
      form_id: this.state.form_id,
      hide: this.state.skip_if == "always"
    };

    let destroy_field_props = {
      type: "hidden",
      name: `${name_prefix}[_destroy]`,
      value: this.shouldDestroy() ? "1" : "0"
    };

    return (
      <div
        className="skip-rule"
        style={{display: this.shouldDestroy() ? "none" : ""}}>
        <div className="skip-rule-main">
          <div className="skip-rule-attribs">
            <FormSelect {...destination_props} />
            <select {...skip_if_props}>
              <option value="always">
                {I18n.t("skip_rule.skip_if_options.always")}
              </option>
              <option value="all_met">
                {I18n.t("skip_rule.skip_if_options.all_met")}
              </option>
              <option value="any_met">
                {I18n.t("skip_rule.skip_if_options.any_met")}
              </option>
            </select>
          </div>
          <ConditionSetFormField {...condition_set_props} />
          <input {...id_field_props} />
          <input {...destroy_field_props} />
          <input
            name={`${name_prefix}[destination]`}
            type="hidden"
            value={this.state.destination} />
          <input
            name={`${name_prefix}[dest_item_id]`}
            type="hidden"
            value={this.state.dest_item_id || ""} />
        </div>
        <div className="skip-rule-remove">
          <a onClick={this.removeRule}>
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
