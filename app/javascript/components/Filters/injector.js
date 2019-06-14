import React from 'react';
import { Provider } from 'mobx-react';

import { provideFiltersStore } from './utils';
import Filters from './component';

/**
 * Provides any needed stores to its children.
 */
const Injector = (props) => {
  const filtersStore = provideFiltersStore();
  const { conditionSetStore } = filtersStore;
  return (
    <Provider filtersStore={filtersStore} conditionSetStore={conditionSetStore}>
      <Filters {...props} />
    </Provider>
  );
};

export default Injector;
