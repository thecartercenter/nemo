class SkipRuleFormField extends React.Component {
  constructor(props) {
    super();
    let dest_item_id_or_end = props.destination == "end" ? "end" : props.dest_item_id;
    this.state = Object.assign({}, props, {dest_item_id_or_end: dest_item_id_or_end});
    console.log(this.state)

    this.changeDestinationOption = this.changeDestinationOption.bind(this);
    this.changeSkipIf = this.changeSkipIf.bind(this);
  }

  changeDestinationOption(value) {
    this.setState({
      dest_item_id_or_end: value,
      destination: value == "end" ? "end" : "item",
      dest_item_id: value == "end" ? null : value
    });
  }

  changeSkipIf(value) {

  }

  formatTargetItemOptions(items) {
    return items.map(function(o){
      return {id: o.id, name: `${o.full_dotted_rank}. ${o.code}`, key: o.id};
    }).concat([{id: "end", name: I18n.t("form_item.end_of_form"), key: "end"}]);
  }

  render() {
    let name_prefix = `questioning[skip_rules_attributes][${this.state.id}]`;

    let destination_props = {
      value: this.state.dest_item_id_or_end || "",
      options: this.formatTargetItemOptions(this.state.later_items),
      changeFunc: this.changeDestinationOption
    };
    let skip_if_props = {
      name: `${name_prefix}[skip_if]`,
      value: this.state.skip_if,
      className: "form-control",
      onChange: this.changeSkipIf
    };

    return (
      <div>
        <FormSelect {...destination_props} />
        <select {...skip_if_props}>
          <option value="always">{I18n.t("form_item.skip_if_options.always")}</option>
          <option value="all_met">{I18n.t("form_item.skip_if_options.all_met")}</option>
          <option value="any_met">{I18n.t("form_item.skip_if_options.any_met")}</option>
        </select>
        <input type="hidden" name={`${name_prefix}[id]`} value={this.state.id || ""} />
        <input type="hidden" name={`${name_prefix}[destination]`} value={this.state.destination} />
        <input type="hidden" name={`${name_prefix}[dest_item_id]`} value={this.state.dest_item_id || ""} />
      </div>
    );
  }
}
