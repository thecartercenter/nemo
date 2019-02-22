import React from "react";
import PropTypes from "prop-types";
import Button from "react-bootstrap/lib/Button";

class FormFilter extends React.Component {
  render() {
    return (
      <Button
        data-content="List!"
        data-placement="bottom"
        data-toggle="popover"
        data-viewport={"{\"selector\": \"body\", \"padding\": 25}"}>
        {I18n.t("filter.form")}
      </Button>
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
