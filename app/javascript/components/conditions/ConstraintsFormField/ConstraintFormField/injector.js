import React from 'react';
import PropTypes from 'prop-types';
import { Provider } from 'mobx-react';

import ConditionSetModel from '../../ConditionSetFormField/model';
import { provideConditionSetStore } from '../../ConditionSetFormField/utils';
import ConstraintFormField from './component';

let forcedResetNonce = 0;

/**
 * Provides any needed stores to its children.
 */
function Injector(props) {
  const {
    constraintId,
    namePrefix,
    conditions,
    id,
    refableQings,
    rejectionMsgTranslations,
  } = props;

  const conditionSetStore = provideConditionSetStore(ConditionSetModel, `constraint-${constraintId}`, {
    namePrefix: `${namePrefix}[conditions_attributes]`,
    conditions,
    conditionableId: id,
    conditionableType: 'Constraint',
    refableQings,
    hide: false,
    rejectionMsgTranslations: rejectionMsgTranslations || {},
  });

  // eslint-disable-next-line no-return-assign
  return (
    <Provider key={forcedResetNonce += 1} conditionSetStore={conditionSetStore}>
      <ConstraintFormField {...props} />
    </Provider>
  );
}

Injector.propTypes = {
  constraintId: PropTypes.string.isRequired,
  namePrefix: PropTypes.string.isRequired,
  conditions: PropTypes.arrayOf(PropTypes.object),
  id: PropTypes.string,
  refableQings: PropTypes.arrayOf(PropTypes.object).isRequired,
  acceptIf: PropTypes.string.isRequired,
  rejectionMsgTranslations: PropTypes.object,
};

export default Injector;
