import isEmpty from 'lodash/isEmpty';
import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

import { getItemNameFromId, getQuestionNameFromId } from '../utils';
import ConditionSetFormField from '../../conditions/ConditionSetFormField/component';
import AddConditionLink from '../../conditions/AddConditionLink/component';
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
    const { filtersStore: { allForms, selectedFormIds } } = this.props;
    const formNames = selectedFormIds.map((id) => getItemNameFromId(allForms, id));
    const formConstraintText = isEmpty(formNames)
      ? null
      : I18n.t('filter.showing_questions_from', { form_list: formNames.join(', ') });

    return (
      <div>
        {formConstraintText
          ? <p className="mb-2">{formConstraintText}</p>
          : null}
        <ConditionSetFormField />
        <AddConditionLink />
      </div>
    );
  };

  render() {
    const { filtersStore: { conditionSetStore }, onSubmit } = this.props;
    const { original: { conditions, refableQings } } = conditionSetStore;
    const hints = conditions
      .filter(({ leftQingId }) => leftQingId)
      .map(({ leftQingId }) => getQuestionNameFromId(refableQings, leftQingId));

    return (
      <FilterOverlayTrigger
        id="question-filter"
        title={I18n.t('filter.question')}
        popoverContent={this.renderPopover()}
        popoverClass="wide display-logic-container"
        buttonsContainerClass="condition-margin"
        onSubmit={onSubmit}
        hints={hints}
        buttonClass="btn-margin-left"
      />
    );
  }
}

export default QuestionFilter;
