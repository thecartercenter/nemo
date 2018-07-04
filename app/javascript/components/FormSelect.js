import React from "react";
import PropTypes from "prop-types";

class FormSelect extends React.Component {
  render() {
    let options = this.props.options;
    let optionTags = [];
    if (this.props.prompt || this.props.includeBlank !== false) {
      optionTags.push(
        <option
          key="blank"
          value="">
          {this.props.prompt || ""}
        </option>
      );
    }
    options.forEach((o) => optionTags.push(
      <option
        key={o.id}
        value={o.id}>
        {o.name}
      </option>
    ));
    let props = {
      className: "form-control",
      name: this.props.name,
      id: this.props.id,
      key: this.props.id,
      defaultValue: this.props.value
    };
    if (this.props.changeFunc) {
      props["onChange"] = (e) => this.props.changeFunc(e.target.value);
    }
    return (
      <select {...props} >
        {optionTags}
      </select>
    );
  }
}

FormSelect.propTypes = {
  changeFunc: PropTypes.func,
  id: PropTypes.string,
  includeBlank: PropTypes.bool,
  name: PropTypes.string,
  options: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string,
    name: PropTypes.string
  })).isRequired,
  prompt: PropTypes.string,
  value: PropTypes.node
};

FormSelect.defaultProps = {
  changeFunc: null,
  id: null,
  includeBlank: true,
  name: null,
  prompt: null,
  value: null
};

export default FormSelect;
