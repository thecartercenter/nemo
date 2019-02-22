import React from "react";
import PropTypes from "prop-types";

class FormFilter extends React.Component {
  render() {
    return (
      <button
        className="btn btn-default"
        data-content="List!"
        data-placement="bottom"
        data-toggle="popover"
        data-viewport={"{\"selector\": \"body\", \"padding\": 25}"}
        type="button">
        {I18n.t("filter.form")}
      </button>
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
