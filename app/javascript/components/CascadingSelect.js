import React from 'react';
import PropTypes from 'prop-types';

import FormSelect from './FormSelect';

class CascadingSelect extends React.Component {
  constructor(props) {
    super(props);
    this.nodeChanged = this.nodeChanged.bind(this);
    this.buildUrl = this.buildUrl.bind(this);
    this.buildLevelProps = this.buildLevelProps.bind(this);
    this.buildLevels = this.buildLevels.bind(this);
    this.isLastLevel = this.isLastLevel.bind(this);
    this.state = props;
  }

  // Refresh data on mount.
  componentDidMount() {
    const { optionSetId, optionNodeId } = this.state;
    this.getData(optionSetId, optionNodeId);
  }

  // Refresh data if the option set is changing.
  componentWillReceiveProps(nextProps) {
    const { optionSetId } = this.state;
    if (nextProps.optionSetId !== optionSetId) {
      this.getData(nextProps.optionSetId, nextProps.optionNodeId);
    }
  }

  // Fetches data to populate the control. nodeId may be null if there is no node selected.
  getData(setId, nodeId) {
    ELMO.app.loading(true);
    const self = this;
    const url = this.buildUrl(setId, nodeId);
    $.ajax(url)
      .done((response) => {
        self.setState(response);
      })
      .always(() => {
        ELMO.app.loading(false);
      });
  }

  // Refresh data if the selected node changed.
  nodeChanged(newNodeId) {
    const { optionSetId } = this.state;
    this.getData(optionSetId, newNodeId);
  }

  buildUrl(setId, nodeId) {
    return `${ELMO.app.url_builder.build('option-sets', setId, 'condition-form-view')}?node_id=${nodeId}`;
  }

  buildLevelProps(level, isLastLevel) {
    const { namePrefix } = this.state;
    return {
      type: 'select',
      name: `${namePrefix}[option_node_ids][]`,
      key: 'display_conditions_attributes_option_node_ids_',
      value: level.selected,
      options: level.options,
      prompt: this.optionPrompt(level),
      changeFunc: isLastLevel ? null : this.nodeChanged,
    };
  }

  buildLevels() {
    const { levels } = this.state;
    const self = this;
    let result = [];
    if (levels) {
      result = levels.map((level, i) => {
        return (
          <div
            className="level"
            key={level.name}
          >
            <FormSelect {...self.buildLevelProps(level, self.isLastLevel(i))} />
          </div>
        );
      });
    }
    return result;
  }

  isLastLevel(i) {
    const { levels } = this.state;
    return levels && levels.length === (i + 1);
  }

  optionPrompt(level) {
    if (level.name) {
      return I18n.t('option_set.option_prompt_with_level', { level: level.name });
    }
    return I18n.t('option_set.option_prompt');
  }

  render() {
    return (
      <div
        className="cascading-selects"
        id="cascading-selects-1"
      >
        {this.buildLevels()}
      </div>
    );
  }
}

CascadingSelect.propTypes = {
  optionNodeId: PropTypes.string,
  optionSetId: PropTypes.string.isRequired,
};

CascadingSelect.defaultProps = {
  optionNodeId: null,
};

export default CascadingSelect;
