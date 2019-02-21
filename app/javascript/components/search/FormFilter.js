import React from "react";
import PropTypes from "prop-types";

class FormFilter extends React.Component {
  render() {
    return (
      <React.Fragment>
        <div>
          {JSON.stringify(this.props.allForms)}
        </div>
        <div>
          {JSON.stringify(this.props.selectedFormIds)}
        </div>
      </React.Fragment>
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
