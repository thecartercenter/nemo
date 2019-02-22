import React from "react";
import PropTypes from "prop-types";

class FormFilter extends React.Component {
  render() {
    return (
      <input
        className="btn btn-default"
        type="button"
        value={I18n.t("filter.form")} />
    );
  }
}

FormFilter.propTypes = {
  allForms: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string,
    displayName: PropTypes.string
  })).isRequired,
  selectedFormIds: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default FormFilter;
