import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

@inject('conditionSetStore')
@observer
class AddConditionLink extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object,
    defaultLeftQingToCurrent: PropTypes.bool,
  };

  static defaultProps = {
    defaultLeftQingToCurrent: false,
  };

  handleAddClick = () => {
    const { defaultLeftQingToCurrent, conditionSetStore: { addCondition } } = this.props;
    addCondition(defaultLeftQingToCurrent);
  };

  render() {
    return (
      <>
        {/* TODO: Improve a11y. */}
        {/* eslint-disable-next-line */}
        <a onClick={this.handleAddClick} tabIndex="0">
          <i className="fa fa-plus add-condition" />
          {' '}
          {I18n.t('form_item.add_condition')}
        </a>
        {/* eslint-enable */}
      </>
    );
  }
}

export default AddConditionLink;
