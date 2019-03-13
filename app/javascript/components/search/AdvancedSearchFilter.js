import React from "react";
import PropTypes from "prop-types";
import Button from "react-bootstrap/lib/Button";

class AdvancedSearchFilter extends React.Component {
  constructor(props) {
    super();
  }

  render() {
    const {onSubmit} = this.props;

    return (
      <div>
        <Button
          className="btn-apply"
          onClick={onSubmit}>
          {I18n.t("common.search")}
        </Button>
      </div>
    );
  }
}

AdvancedSearchFilter.propTypes = {
  onSubmit: PropTypes.func.isRequired,
};

export default AdvancedSearchFilter;
