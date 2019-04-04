import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import Popover from 'react-bootstrap/Popover';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';

import { getButtonHintString } from './utils';
import ConditionSetFormField from '../ConditionSetFormField';

class QuestionFilter extends React.Component {
  renderPopover = () => {
    const { onSubmit } = this.props;

    const conditionSetProps = {
      conditions: [],
      conditionableId: 'id',
      conditionableType: 'FormItem',
      refableQings: [],
      formId: 'id',
      namePrefix: 'type[display_conditions_attributes]',
    };

    return (
      <Popover
        className="filters-popover display-logic-container"
        id="form-filter"
      >
        <ConditionSetFormField {...conditionSetProps} />

        <div className="btn-apply-container">
          <Button
            className="btn-apply"
            onClick={onSubmit}
          >
            {I18n.t('common.apply')}
          </Button>
        </div>
      </Popover>
    );
  }

  render() {
    return (
      <OverlayTrigger
        id="question-filter"
        containerPadding={25}
        overlay={this.renderPopover()}
        placement="bottom"
        rootClose
        trigger="click"
      >
        <Button id="question-filter" className="btn-secondary btn-margin-left">
          {I18n.t('filter.question') + getButtonHintString([])}
        </Button>
      </OverlayTrigger>
    );
  }
}

QuestionFilter.propTypes = {
  onSubmit: PropTypes.func.isRequired,
};

export default QuestionFilter;
