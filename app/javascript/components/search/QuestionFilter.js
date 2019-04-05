import queryString from 'query-string';
import React from 'react';
import PropTypes from 'prop-types';
import Button from 'react-bootstrap/Button';
import Popover from 'react-bootstrap/Popover';
import OverlayTrigger from 'react-bootstrap/OverlayTrigger';

import { getButtonHintString } from './utils';
import ConditionSetFormField from '../ConditionSetFormField';

class QuestionFilter extends React.Component {
  static propTypes = {
    selectedFormIds: PropTypes.arrayOf(PropTypes.string).isRequired,
    onSubmit: PropTypes.func.isRequired,
  };

  state = {
    refableQings: [],
  };

  componentWillMount() {
    // TODO: Also handle updating data on change.
    this.getData();
  }

  getData = async () => {
    ELMO.app.loading(true);
    const url = this.buildUrl();
    try {
      const { refableQings } = await $.ajax(url);
      this.setState({ refableQings });
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

  getSelectedFormId = () => {
    const { selectedFormIds } = this.props;
    // For now we can assume only one form is selected at once.
    return selectedFormIds[0] || '';
  }

  renderPopover = () => {
    const { onSubmit } = this.props;
    const { refableQings } = this.state;
    const formId = this.getSelectedFormId();

    return (
      <Popover
        className="filters-popover display-logic-container"
        id="form-filter"
      >
        <ConditionSetFormField
          conditionableId={formId}
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
