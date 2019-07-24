import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import { inject, observer } from 'mobx-react';

@inject('filtersStore')
@observer
class AdvancedSearchFilter extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object,
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
    const { filtersStore, onSubmit } = this.props;
    const { advancedSearchText, handleChangeAdvancedSearch } = filtersStore;

    return (
      <div className="d-flex">
        <i className="fa fa-search" />
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
      </div>
    );
  }
}

export default AdvancedSearchFilter;
