import React from "react";
import PropTypes from "prop-types";
import Button from "react-bootstrap/lib/Button";

class AdvancedSearchFilter extends React.Component {
  constructor(props) {
    super();
  }

  render() {
    const {advancedSearchText, onChangeAdvancedSearch, onSubmit} = this.props;

    return (
      <div>
        <input
          autoComplete="off"
          className="form-control"
          id="search_str"
          name="search"
          onChange={onChangeAdvancedSearch}
          placeholder={I18n.t("filter.advancedSearch")}
          type="text"
          value={advancedSearchText} />
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
  advancedSearchText: PropTypes.string.isRequired,
  onChangeAdvancedSearch: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
};

export default AdvancedSearchFilter;
