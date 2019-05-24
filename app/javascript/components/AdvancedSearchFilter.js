import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import { inject, observer } from 'mobx-react';

import { isQueryParamTruthy } from './search/utils';

@inject('filtersStore')
@observer
class AdvancedSearchFilter extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object,
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
    const { filtersStore, onClear, onSubmit } = this.props;
    const { advancedSearchText, handleChangeAdvancedSearch } = filtersStore;

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
          onChange={handleChangeAdvancedSearch}
        />
        <Button
          variant="secondary"
          className="btn-apply btn-advanced-search"
          onClick={onSubmit}
        >
          {I18n.t('common.search')}
        </Button>
        {isQueryParamTruthy('search') ? (
          <Button
            variant="secondary"
            className="btn-clear btn-margin-left"
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
