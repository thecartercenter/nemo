class SkipLogicFormField extends React.Component {
  constructor(props) {
    super();
    let skip = props.skip_rules.length == 0 ? 'dont_skip' : 'skip';
    this.state = Object.assign({}, props, {skip: skip});
    this.changeSkipOption = this.changeSkipOption.bind(this);
  }

  changeSkipOption(event) {
    this.setState({skip: event.target.value});
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
        <SkipRuleSetFormField show={this.state.skip == "skip"} {...this.state} />
      </div>
    );
  }
}
