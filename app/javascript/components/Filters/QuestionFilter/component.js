import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

import { getItemNameFromId } from '../utils';
import ConditionSetFormField from '../../conditions/ConditionSetFormField/component';
import FilterPopover from '../FilterPopover/component';
import FilterOverlayTrigger from '../FilterOverlayTrigger/component';

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
      <FilterPopover
        className="wide display-logic-container"
        id="question-filter"
        onSubmit={onSubmit}
        buttonsContainerClass="condition-margin"
      >
        <ConditionSetFormField />
      </FilterPopover>
    );
  }

  render() {
    const { filtersStore: { conditionSetStore } } = this.props;
    const { originalConditions, refableQings } = conditionSetStore;
    const hints = originalConditions
      .filter(({ leftQingId }) => leftQingId)
      .map(({ leftQingId }) => getItemNameFromId(refableQings, leftQingId, 'code'));

    return (
      <FilterOverlayTrigger
        id="question-filter"
        title={I18n.t('filter.question')}
        overlay={this.renderPopover()}
        hints={hints}
        buttonClass="btn-margin-left"
      />
    );
  }
}

export default QuestionFilter;
