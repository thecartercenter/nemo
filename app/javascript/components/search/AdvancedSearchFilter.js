import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';

import { isQueryParamTruthy } from './utils';

class AdvancedSearchFilter extends React.Component {
  static propTypes = {
    advancedSearchText: PropTypes.string.isRequired,
    onChangeAdvancedSearch: PropTypes.func.isRequired,
    onClear: PropTypes.func.isRequired,
    onSubmit: PropTypes.func.isRequired,
  };

  handleKeyDown = (event) => {
    const { onSubmit } = this.props;

    if (event.key === 'Enter') {
      event.preventDefault();
      onSubmit();
    }
  }

  render() {
    const { advancedSearchText, onChangeAdvancedSearch, onClear, onSubmit } = this.props;

    return (
      <div>
        <input
          className="form-control search-str"
          type="text"
          name="search"
          autoComplete="off"
          value={advancedSearchText}
          placeholder={I18n.t('filter.advancedSearch')}
          onKeyDown={this.handleKeyDown}
          onChange={onChangeAdvancedSearch}
        />
        <Button
          className="btn-apply btn-advanced-search btn-secondary"
          onClick={onSubmit}
        >
          {I18n.t('common.search')}
        </Button>
        {isQueryParamTruthy('search') ? (
          <Button
            className="btn-clear btn-secondary btn-margin-left"
            onClick={onClear}
          >
            {I18n.t('common.clear')}
          </Button>
        ) : null}
      </div>
    );
  }
}

export default AdvancedSearchFilter;
