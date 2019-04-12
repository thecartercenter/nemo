import queryString from 'query-string';
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

  componentWillMount() {
    // TODO: Also handle updating data on change.
    this.getData();
  }

  getData = async () => {
    const { filtersStore: { conditionSetStore } } = this.props;

    ELMO.app.loading(true);
    const url = this.buildUrl();
    try {
      const { refableQings } = await $.ajax(url);
      conditionSetStore.refableQings = refableQings;
    } catch (error) {
      console.error('Failed to getData:', error);
    } finally {
      ELMO.app.loading(false);
    }
  }

  buildUrl = () => {
    const formId = this.getSelectedFormId();
    const params = {
      conditionable_id: formId || undefined,
      conditionable_type: formId ? 'FormItem' : undefined,
    };
    const url = ELMO.app.url_builder.build('form-items', 'condition-form');
    return `${url}?${queryString.stringify(params)}`;
  }

  renderPopover = () => {
    const { filtersStore, onSubmit } = this.props;
    const { conditionSetStore: { refableQings }, selectedFormId } = filtersStore;

    return (
      <Popover
        className="filters-popover display-logic-container"
        id="form-filter"
      >
        <ConditionSetFormField
          conditionableId={selectedFormId}
          conditionableType="FormItem"
          refableQings={refableQings}
        />

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

export default QuestionFilter;
