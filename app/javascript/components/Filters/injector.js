import React from 'react';
import PropTypes from 'prop-types';
import { Provider } from 'mobx-react';

import FiltersModel from './model';
import { provideFiltersStore } from './utils';
import { submitterType } from './SubmitterFilter/utils';
import Filters from './component';

let forcedResetNonce = 0;

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
    startDate,
    endDate,
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
    startDate,
    endDate,
  });
  const { conditionSetStore } = filtersStore;

  // eslint-disable-next-line no-return-assign
  return (
    <Provider key={forcedResetNonce += 1} filtersStore={filtersStore} conditionSetStore={conditionSetStore}>
      <Filters {...props} />
    </Provider>
  );
}

Injector.propTypes = {
  allForms: PropTypes.arrayOf(PropTypes.shape({
    id: PropTypes.string,
    name: PropTypes.string,
  })),
  selectedFormIds: PropTypes.arrayOf(PropTypes.string),
  selectedQings: PropTypes.arrayOf(PropTypes.object),
  isReviewed: PropTypes.bool,
  selectedUsers: PropTypes.arrayOf(PropTypes.object),
  selectedGroups: PropTypes.arrayOf(PropTypes.object),
  advancedSearchText: PropTypes.string.isRequired,
  startDate: PropTypes.string,
  endDate: PropTypes.string,
};

export default Injector;
