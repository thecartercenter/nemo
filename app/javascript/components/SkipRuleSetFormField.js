import React from "react";
import PropTypes from "prop-types";

import SkipRuleFormField from "./SkipRuleFormField";

class SkipRuleSetFormField extends React.Component {
  constructor(props) {
    super();
    this.state = props;
    this.handleAddClick = this.handleAddClick.bind(this);
  }

  // If about to show the set and it's empty, add a blank one.
  componentWillReceiveProps(newProps) {
    if (!newProps.hide && this.props.hide && this.state.skipRules.length === 0) {
      this.handleAddClick();
    }
  }

  handleAddClick() {
    let laterItemsExist = this.state.laterItems.length > 0;
    this.setState(curState => ({skipRules:
      curState.skipRules.concat([{
        key: Math.round(Math.random() * 100000000),
        destination: laterItemsExist ? "item" : "end",
        skipIf: "always",
        conditions: []
      }])}));
  }

  render() {
    return (
      <div
        className="skip-rule-set"
        style={{display: this.props.hide ? "none" : ""}}>
        {this.state.skipRules.map((props, index) => (<SkipRuleFormField
          formId={this.state.formId}
          hide={this.props.hide}
          key={props.key || props.id}
          laterItems={this.state.laterItems}
          ruleId={`rule-${index + 1}`}
          namePrefix={`${this.state.type}[skip_rules_attributes][${index}]`}
          refableQings={this.state.refableQings}
          {...props} />))}
        <div
          className="skip-rule-add-link-wrapper">
          <a
            onClick={this.handleAddClick}
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
  hide: PropTypes.bool.isRequired
};

export default SkipRuleSetFormField;
