import React from 'react';
import PropTypes from 'prop-types';

import ConstraintFormField from './ConstraintFormField';

class ConstraintSetFormField extends React.Component {
  static propTypes = {
    hide: PropTypes.bool.isRequired,
    constraints: PropTypes.arrayOf(PropTypes.object),
    refableQings: PropTypes.arrayOf(PropTypes.object),
  };

  constructor(props) {
    super(props);
    const { constraints } = this.props;
    this.state = { constraints };
  }

  // If about to show the set and it's empty, add a blank one.
  componentWillReceiveProps(newProps) {
    const { hide } = this.props;
    const { constraints } = this.state;
    if (!newProps.hide && hide && constraints.length === 0) {
      this.handleAddClick();
    }
  }

  handleAddClick = () => {
    this.setState(({ constraints }) => ({
      constraints: constraints.concat([{
        key: Math.round(Math.random() * 100000000),
        acceptIf: 'all_met',
        conditions: [],
      }]),
    }));
  }

  render() {
    const { hide, refableQings } = this.props;
    const { constraints } = this.state;

    return (
      <div
        className="rule-set"
        style={{ display: hide ? 'none' : '' }}
      >
        {constraints.map((constraint, index) => (
          <ConstraintFormField
            hide={hide}
            key={constraint.key || constraint.id}
            constraintId={`constraint-${index + 1}`}
            namePrefix={`questioning[constraints_attributes][${index}]`}
            refableQings={refableQings}
            {...constraint}
          />
        ))}
        <div
          className="rule-add-link-wrapper"
        >
          {/* TODO: Improve a11y. */}
          {/* eslint-disable */}
          <a
            onClick={this.handleAddClick}
            tabIndex="0"
          >
          {/* eslint-enable */}
            <i className="fa fa-plus" />
            {' '}
            {I18n.t('form_item.add_constraint')}
          </a>
        </div>
      </div>
    );
  }
}

export default ConstraintSetFormField;
