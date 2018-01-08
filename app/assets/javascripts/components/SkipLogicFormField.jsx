class SkipLogicFormField extends React.Component {
  constructor(props) {
    super();
    let skip = props.skip_rules.length == 0 ? 'dont_skip' : 'skip';
    this.state = Object.assign({}, props, {skip: skip});
    this.changeSkipOption = this.changeSkipOption.bind(this);

    // Add reference to later_items to each skip rule.
    let self = this;
    this.state.skip_rules.forEach((r) => r.later_items = self.state.later_items);
  }

  changeSkipOption(event) {
    this.setState({skip: event.target.value});
  }

  buildSkipRules(args) {
    return (
      <div>
        {this.state.skip_rules.map((props, index) => <SkipRuleFormField key={index} {...props}/>)}
      </div>
    )
  }

  render() {
    let select_props = {
      className: "form-control",
      value: this.state.skip,
      onChange: this.changeSkipOption
    };

    return (
      <div>
        <select {...select_props}>
          <option value="dont_skip">{I18n.t('form_item.skip_logic_options.dont_skip')}</option>
          <option value="skip">{I18n.t('form_item.skip_logic_options.skip')}</option>
        </select>
        {this.buildSkipRules()}
      </div>
    );
  }
}
