class SkipRuleSetFormField extends React.Component {
  constructor(props) {
    super();
    this.state = props;
    this.addRule = this.addRule.bind(this);
  }

  // If about to show the set and it's empty, add a blank one.
  componentWillReceiveProps(newProps) {
    if (!newProps.hide && this.props.hide && this.state.skipRules.length == 0) {
      this.addRule();
    }
  }

  addRule() {
    let laterItemsExist = this.state.laterItems.length > 0;
    this.setState({skipRules:
      this.state.skipRules.concat([{
        destination: laterItemsExist ? "item" : "end",
        skipIf: "always",
        conditions: []
      }])});
  }

  render() {
    return (
      <div
        className="skip-rule-set"
        style={{display: this.props.hide ? "none" : ""}}>
        {this.state.skipRules.map((props, index) => (<SkipRuleFormField
          formId={this.state.formId}
          hide={this.props.hide}
          key={index}
          laterItems={this.state.laterItems}
          namePrefix={`questioning[skip_rules_attributes][${index}]`}
          refableQings={this.state.refableQings}
          {...props} />))}
        <div
          className="skip-rule-add-link-wrapper">
          <a
            onClick={this.addRule}
            tabIndex="0">
            <i className="fa fa-plus" />
            {" "}
            {I18n.t("form_item.add_rule")}
          </a>
        </div>
      </div>
    );
  }
}

SkipRuleSetFormField.propTypes = {
  hide: React.PropTypes.bool.isRequired
};
