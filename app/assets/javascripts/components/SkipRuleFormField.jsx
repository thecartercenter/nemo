class SkipRuleFormField extends React.Component {
  constructor(props) {
    super();

    let destItemIdOrEnd = props.destination == "end" ? "end" : props.destItemId;
    this.state = Object.assign({}, props, {destItemIdOrEnd: destItemIdOrEnd});

    this.destinationOptionChanged = this.destinationOptionChanged.bind(this);
    this.skipIfChanged = this.skipIfChanged.bind(this);
    this.removeRule = this.removeRule.bind(this);
  }

  destinationOptionChanged(value) {
    this.setState({
      destItemIdOrEnd: value,
      destination: value == "end" ? "end" : "item",
      destItemId: value == "end" ? null : value
    });
  }

  skipIfChanged(event) {
    this.setState({
      skipIf: event.target.value
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
        name: I18n.t("skip_rule.skip_to_item", {label: `${o.fullDottedRank}. ${o.code}`})
      };
    }).concat([{id: "end", name: I18n.t("form_item.end_of_form"), key: "end"}]);
  }

  render() {
    let namePrefix = this.props.namePrefix;

    let idFieldProps = {
      type: "hidden",
      name: `${namePrefix}[id]`,
      value: this.state.id || ""
    };

    let destinationProps = {
      value: this.state.destItemIdOrEnd || "",
      prompt: I18n.t("skip_rule.dest_prompt"),
      options: this.formatTargetItemOptions(this.state.laterItems),
      changeFunc: this.destinationOptionChanged
    };

    let skipIfProps = {
      name: `${namePrefix}[skip_if]`,
      value: this.state.skipIf,
      className: "form-control",
      onChange: this.skipIfChanged
    };

    let conditionSetProps = {
      conditions: this.state.conditions,
      conditionableId: this.state.id,
      conditionableType: "SkipRule",
      refableQings: this.state.refableQings,
      namePrefix: `${namePrefix}[conditions_attributes]`,
      formId: this.state.formId,
      hide: this.state.skipIf == "always"
    };

    let destroyFieldProps = {
      type: "hidden",
      name: `${namePrefix}[_destroy]`,
      value: this.shouldDestroy() ? "1" : "0"
    };

    return (
      <div
        className="skip-rule"
        style={{display: this.shouldDestroy() ? "none" : ""}}>
        <div className="skip-rule-main">
          <div className="skip-rule-attribs">
            <FormSelect {...destinationProps} />
            <select {...skipIfProps}>
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
          <ConditionSetFormField {...conditionSetProps} />
          <input {...idFieldProps} />
          <input {...destroyFieldProps} />
          <input
            name={`${namePrefix}[destination]`}
            type="hidden"
            value={this.state.destination} />
          <input
            name={`${namePrefix}[dest_item_id]`}
            type="hidden"
            value={this.state.destItemId || ""} />
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
