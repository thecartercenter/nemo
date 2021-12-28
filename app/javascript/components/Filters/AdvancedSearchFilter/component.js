import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import { inject, observer } from 'mobx-react';

@inject('filtersStore')
@observer
class AdvancedSearchFilter extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object,
    renderInfoButton: PropTypes.bool,
    onSubmit: PropTypes.func.isRequired,
  };

  handleKeyDown = (callback) => (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      callback();
    }
  };

  showSearchHelp = () => {
    $('#search-help-modal').modal('show');
  };

  render() {
    const { filtersStore, renderInfoButton, onSubmit } = this.props;
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
          placeholder={I18n.t('filter.search_box_placeholder')}
          onKeyDown={this.handleKeyDown(onSubmit)}
          onChange={handleChangeAdvancedSearch}
        />
        <Button
          variant="secondary"
          className="btn-apply btn-advanced-search"
          onClick={onSubmit}
        >
          {I18n.t('common.search')}
        </Button>
        {renderInfoButton ? (
          <i
            className="fa fa-info-circle hint"
            role="button"
            aria-label={I18n.t('search.help_title')}
            tabIndex={0}
            onKeyDown={this.handleKeyDown(this.showSearchHelp)}
            onClick={this.showSearchHelp}
          />
        ) : null}
      </div>
    );
  }
}

export default AdvancedSearchFilter;
