class SkipRuleSetFormField extends React.Component {
  constructor(props) {
    super();
    this.state = props;
    this.addRule = this.addRule.bind(this);
  }

  // If about to show the set and it's empty, add a blank one.
  componentWillReceiveProps(newProps) {
    if (!newProps.hide && this.props.hide && this.state.skip_rules.length == 0) {
      this.addRule();
    }
  }

  addRule() {
    this.setState({skip_rules:
      this.state.skip_rules.concat([{
        destination: this.state.later_items.length > 0 ? "item" : "end",
        dest_item_id: this.state.later_items[0].id,
        skip_if: "always",
        conditions: []
      }])
    });
  }

  render() {
    return (
      <div className="skip-rule-set" style={{display: this.props.hide ? 'none' : ''}}>
        {this.state.skip_rules.map((props, index) =>
          <SkipRuleFormField
            key={index}
            later_items={this.state.later_items}
            refable_qings={this.state.refable_qings}
            form_id={this.state.form_id}
            hide={this.props.hide}
            name_prefix={`questioning[skip_rules_attributes][${index}]`}
            {...props}/>)}
        <a onClick={this.addRule}><i className="fa fa-plus"></i> {I18n.t("form_item.add_rule")}</a>
      </div>
    );
  }
}
