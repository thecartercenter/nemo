import React from "react"
import PropTypes from "prop-types"
class FormFilter extends React.Component {
  render () {
    return (
      <React.Fragment>
        All Forms: {this.props.allForms}
        Selected Form: {this.props.selectedFormIds}
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
export default FormFilter
