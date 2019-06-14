import React from 'react';
import PropTypes from 'prop-types';
import { Provider } from 'mobx-react';

import { provideConditionSetStore } from '../ConditionSetFormField/utils';
import DisplayLogicFormField from './component';

/**
 * Provides any needed stores to its children.
 */
function Injector(props) {
  const {
    refableQings,
    id,
    type,
    displayIf,
    displayConditions,
    formId,
  } = props;

  const conditionSetStore = provideConditionSetStore('displayLogic', {
    formId,
    namePrefix: `${type}[display_conditions_attributes]`,
    conditions: displayConditions,
    conditionableId: id,
    conditionableType: 'FormItem',
    // Display logic conditions can't reference self, as that doesn't make sense.
    refableQings: refableQings.filter((qing) => qing.id !== id),
    hide: displayIf === 'always',
  });

  return (
    <Provider conditionSetStore={conditionSetStore}>
      <DisplayLogicFormField {...props} />
    </Provider>
  );
}

Injector.propTypes = {
  // TODO: Describe these prop types.
  /* eslint-disable react/forbid-prop-types */
  refableQings: PropTypes.any,
  id: PropTypes.any,
  type: PropTypes.any,
  displayIf: PropTypes.any,
  displayConditions: PropTypes.any,
  formId: PropTypes.any,
  /* eslint-enable */
};

export default Injector;
