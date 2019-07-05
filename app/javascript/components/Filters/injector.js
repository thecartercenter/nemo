import React from 'react';
import PropTypes from 'prop-types';
import { Provider } from 'mobx-react';

import FiltersModel from './model';
import { provideFiltersStore } from './utils';
import { submitterType } from './SubmitterFilter/utils';
import Filters from './component';

/**
 * Provides any needed stores to its children.
 */
function Injector(props) {
  const {
    allForms,
    selectedFormIds,
    selectedQings,
    isReviewed,
    selectedUsers,
    selectedGroups,
    advancedSearchText,
  } = props;

  const filtersStore = provideFiltersStore(FiltersModel, {
    allForms,
    selectedFormIds,
    selectedQings,
    isReviewed,
    selectedSubmittersForType: {
      [submitterType.USER]: selectedUsers,
      [submitterType.GROUP]: selectedGroups,
    },
    advancedSearchText,
  });
  const { conditionSetStore } = filtersStore;

  return (
    <Provider filtersStore={filtersStore} conditionSetStore={conditionSetStore}>
      <Filters {...props} />
    </Provider>
  );
}

Injector.propTypes = {
  allForms: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string,
    name: PropTypes.string,
  })).isRequired,
  selectedFormIds: PropTypes.arrayOf(PropTypes.string).isRequired,
  selectedQings: PropTypes.arrayOf(PropTypes.object).isRequired,
  isReviewed: PropTypes.bool,
  selectedUsers: PropTypes.arrayOf(PropTypes.object).isRequired,
  selectedGroups: PropTypes.arrayOf(PropTypes.object).isRequired,
  advancedSearchText: PropTypes.string.isRequired,
};

export default Injector;
