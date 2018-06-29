import React from "react";
import PropTypes from "prop-types";

import CascadingSelect from "./CascadingSelect";

class ConditionValueField extends React.Component {
  render() {
    if (this.props.type === "cascading_select") {
      return <CascadingSelect {...this.props} />;
    } else {
      return (<input
        className="text form-control"
        defaultValue={this.props.value}
        id={this.props.id}
        key="input"
        name={this.props.name}
        type="text" />);
    }
  }
}

ConditionValueField.propTypes = {
  id: PropTypes.string.isRequired,
  name: PropTypes.string,
  type: PropTypes.string.isRequired,
  value: PropTypes.string
};

// These are not needed for CascadingSelect
ConditionValueField.defaultProps = {
  name: null,
  value: null
};

export default ConditionValueField;
