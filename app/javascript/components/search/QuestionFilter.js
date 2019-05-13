import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import Popover from 'react-bootstrap/Popover';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';
import { inject, observer } from 'mobx-react';

import { getButtonHintString } from './utils';
import ConditionSetFormField from '../ConditionSetFormField';

@inject('filtersStore')
@observer
class QuestionFilter extends React.Component {
  static propTypes = {
    filtersStore: PropTypes.object,
    onSubmit: PropTypes.func.isRequired,
  };

  async componentDidMount() {
    const { filtersStore } = this.props;
    await filtersStore.updateRefableQings();
  }

  renderPopover = () => {
    const { onSubmit } = this.props;

    return (
      <Popover
        className="filters-popover wide display-logic-container"
        id="form-filter"
      >
        <ConditionSetFormField />

        <div className="btn-apply-container condition-margin">
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
    const { filtersStore: { conditionSetStore: { originalConditions } } } = this.props;
    const hints = originalConditions.length ? [originalConditions.length] : [];

    return (
      <OverlayTrigger
        id="question-filter"
        containerPadding={25}
        overlay={this.renderPopover()}
        placement="bottom"
        rootClose
        trigger="click"
      >
        <Button id="question-filter" variant="secondary" className="btn-margin-left">
          {I18n.t('filter.question') + getButtonHintString(hints)}
        </Button>
      </OverlayTrigger>
    );
  }
}

export default QuestionFilter;
