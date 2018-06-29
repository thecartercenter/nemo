import React from "react";
import PropTypes from "prop-types";

import ConditionFormField from "./ConditionFormField";

class ConditionSetFormField extends React.Component {
  constructor(props) {
    super();
    this.state = props;
    this.handleAddClick = this.handleAddClick.bind(this);
  }

  // If about to show the set and it's empty, add a blank one.
  componentWillReceiveProps(newProps) {
    if (!newProps.hide && this.props.hide && this.state.conditions.length === 0) {
      this.handleAddClick();
    }
  }

  handleAddClick() {
    this.setState(curState => ({conditions:
      curState.conditions.concat([{
        key: Math.round(Math.random() * 100000000),
        formId: curState.formId,
        refableQings: curState.refableQings,
        operatorOptions: [],
        conditionableId: curState.conditionableId,
        conditionableType: curState.conditionableType
      }])}));
  }

  render() {
    return (
      <div
        className="condition-set"
        style={{display: this.props.hide ? "none" : ""}}>
        {this.state.conditions.map((props, index) => (<ConditionFormField
          hide={this.props.hide}
          index={index}
          key={props.key || props.id}
          namePrefix={this.state.namePrefix}
          {...props} />))}
        <a
          onClick={this.handleAddClick}
          tabIndex="0">
          <i className="fa fa-plus add-condition" />
          {" "}
          {I18n.t("form_item.add_condition")}
        </a>
      </div>
    );
  }
}

ConditionSetFormField.propTypes = {
  hide: PropTypes.bool.isRequired
};

export default ConditionSetFormField;
