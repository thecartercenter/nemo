import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

@inject('conditionSetStore')
@observer
class AddConditionLink extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object,
  };

  render() {
    const { conditionSetStore: { handleAddClick } } = this.props;

    return (
      <span>
        {/* TODO: Improve a11y. */}
        {/* eslint-disable */}
        <a
          onClick={handleAddClick}
          tabIndex="0"
        >
          <i className="fa fa-plus add-condition" />
          {' '}
          {I18n.t('form_item.add_condition')}
        </a>
        {/* eslint-enable */}
      </span>
    );
  }
}

export default AddConditionLink;
