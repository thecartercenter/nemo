import queryString from 'query-string';
import React from 'react';
import PropTypes from 'prop-types';

import FormSelect from './FormSelect';

class CascadingSelect extends React.Component {
  static propTypes = {
    optionNodeId: PropTypes.string,
    optionSetId: PropTypes.string.isRequired,
    onChange: PropTypes.func,

    // TODO: Describe these prop types.
    /* eslint-disable react/forbid-prop-types */
    namePrefix: PropTypes.any,
    levels: PropTypes.any,
    /* eslint-enable */
  };

  constructor(props) {
    super(props);
    const { optionSetId, optionNodeId, namePrefix, levels } = this.props;
    this.state = { optionSetId, optionNodeId, namePrefix, levels };
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
  getData = async (setId, nodeId) => {
    ELMO.app.loading(true);
    const url = this.buildUrl(setId, nodeId);
    try {
      // TODO: Decompose magical `response` before setting state.
      const response = await $.ajax(url);
      this.setState(response);
    } catch (error) {
      console.error('Failed to getData:', error);
    } finally {
      ELMO.app.loading(false);
    }
  }

  nodeChanged = (isLastLevel) => (newNodeId) => {
    const { onChange } = this.props;
    const { optionSetId } = this.state;

    if (onChange) {
      onChange(newNodeId);
    }

    if (!isLastLevel) {
      this.getData(optionSetId, newNodeId);
    }
  }

  buildUrl = (setId, nodeId) => {
    const params = { node_id: nodeId };
    const url = ELMO.app.url_builder.build('option-sets', setId, 'condition-form-view');
    return `${url}?${queryString.stringify(params)}`;
  }

  buildLevelProps = (level, isLastLevel) => {
    const { namePrefix } = this.state;
    return {
      type: 'select',
      name: `${namePrefix}[option_node_ids][]`,
      key: 'display_conditions_attributes_option_node_ids_',
      value: level.selected,
      options: level.options,
      prompt: this.optionPrompt(level),
      onChange: this.nodeChanged(isLastLevel),
    };
  }

  buildLevels = () => {
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

  isLastLevel = (i) => {
    const { levels } = this.state;
    return levels && levels.length === (i + 1);
  }

  optionPrompt = (level) => {
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

export default CascadingSelect;
