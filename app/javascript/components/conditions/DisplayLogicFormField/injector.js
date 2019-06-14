import React from 'react';
import { Provider } from 'mobx-react';

import { provideConditionSetStore } from '../ConditionSetFormField/utils';
import DisplayLogicFormField from './component';

/**
 * Provides any needed stores to its children.
 */
const Injector = (props) => (
  <Provider conditionSetStore={provideConditionSetStore('displayLogic')}>
    <DisplayLogicFormField {...props} />
  </Provider>
);

export default Injector;
