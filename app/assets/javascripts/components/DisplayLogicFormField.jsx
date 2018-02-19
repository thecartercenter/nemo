class DisplayLogicFormField extends React.Component {
  constructor(props) {
    super();
    this.state = props;
    this.displayIfChanged = this.displayIfChanged.bind(this);
  }

  displayIfChanged(event) {
    let value = event.target.value;
    this.setState({display_if: value});
  }

  render() {
    // Display logic conditions can't reference self, as that doesn't make sense.
    let refable_qings = this.state.refable_qings.slice(0, -1);

    if (refable_qings.length == 0) {
      return (
        <div>
          {I18n.t("condition.no_refable_qings")}
        </div>
      );
    } else {
      let display_if_props = {
        className: "form-control",
        name: "questioning[display_if]",
        id: "questioning_display_logic",
        value: this.state.display_if,
        onChange: this.displayIfChanged
      };

      let condition_set_props = {
        conditions: this.state.display_conditions,
        conditionable_id: this.state.id,
        conditionable_type: "FormItem",
        refable_qings: refable_qings,
        form_id: this.state.form_id,
        hide: this.state.display_if == "always",
        name_prefix: "questioning[display_conditions_attributes]"
      };

      return (
        <div>
          <select {...display_if_props}>
            <option value="always">
              {I18n.t("form_item.display_if_options.always")}
            </option>
            <option value="all_met">
              {I18n.t("form_item.display_if_options.all_met")}
            </option>
            <option value="any_met">
              {I18n.t("form_item.display_if_options.any_met")}
            </option>
          </select>
          <ConditionSetFormField {...condition_set_props} />
        </div>
      );
    }
  }
}
