import React from 'react';
import { Provider } from 'mobx-react';

import { provideConditionSetStore } from '../ConditionSetFormField/utils';
import DisplayLogicFormField from './component';

/**
 * Provides any needed stores to its children.
 */
function Injector(props) {
  const conditionSetStore = provideConditionSetStore('displayLogic');

  return (
    <Provider conditionSetStore={conditionSetStore}>
      <DisplayLogicFormField {...props} />
    </Provider>
  );
}

export default Injector;
