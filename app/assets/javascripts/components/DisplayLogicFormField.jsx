class DisplayLogicFormField extends React.Component {


  constructor(props) {
    super();
    this.state = props;
    this.changeDisplayOption = this.changeDisplayOption.bind(this);
    this.buildConditions = this.buildConditions.bind(this);
    this.addCondition = this.addCondition.bind(this)
  }

  changeDisplayOption(event) {
    let value = event.target.value

    this.setState({display_if: value})
  }

  buildConditions(args) {
    if(this.state.display_if != "always") {
      return (
        <div>
          {this.state.display_conditions.map((props, index) => <ConditionsFormField key={index} {...props}/>)}
          <button onClick={this.addCondition} type="button">Add Condition</button>
        </div>
      )
    }
  }

  addCondition() {
    let conditions = this.state.display_conditions
    conditions.push({refable_qings: this.state.refable_qings, operator_options: [], questioning_id: this.state.id})

    this.setState({display_conditions: conditions})
  }

  render() {
    let select_props = {
      className: "form-control",
      name: "questioning[display_if]",
      id: "questioning_display_if",
      value: this.state.display_if,
      onChange: this.changeDisplayOption
    }

    return (
      <div>
        <select {...select_props}>
          <option value="always">{I18n.t("form_item.display_if_options.always")}</option>
          <option value="all_met">{I18n.t("form_item.display_if_options.all_met")}.</option>
          <option value="any_met">{I18n.t("form_item.display_if_options.any_met")}</option>
        </select>
        {this.buildConditions()}
      </div>
    );
  }
}
