import React from 'react';
import PropTypes from 'prop-types';
import { observer } from 'mobx-react';

import FormSelect from '../../../../FormSelect/component';

@observer
class CascadingSelect extends React.Component {
  static propTypes = {
    namePrefix: PropTypes.string,
    optionNodeId: PropTypes.string,
    optionSetId: PropTypes.string.isRequired,
    levels: PropTypes.arrayOf(PropTypes.object),
    updateLevels: PropTypes.func.isRequired,
    onChange: PropTypes.func,
  };

  async componentDidMount() {
    const { updateLevels } = this.props;
    await updateLevels();
  }

  nodeChanged = (level, levelIndex) => (newNodeId) => {
    const { onChange, updateLevels } = this.props;
    const isLastLevel = this.isLastLevel(levelIndex);

    if (onChange) {
      onChange(newNodeId, level.name);
    }

    // Refresh data if the selected node changed.
    if (!isLastLevel) {
      updateLevels(newNodeId);
    }
  };

  buildLevelProps = (level, levelIndex) => {
    const { namePrefix } = this.props;
    return {
      type: 'select',
      name: `${namePrefix}[option_node_ids][]`,
      key: 'display_conditions_attributes_option_node_ids_',
      value: level.selected,
      options: level.options,
      prompt: this.optionPrompt(level),
      onChange: this.nodeChanged(level, levelIndex),
    };
  };

  buildLevels = () => {
    const { levels } = this.props;
    let result = [];
    if (levels) {
      result = levels.map((level, index) => {
        return (
          <div
            className="level"
            key={level.name}
          >
            <FormSelect {...this.buildLevelProps(level, index)} />
          </div>
        );
      });
    }
    return result;
  };

  isLastLevel = (i) => {
    const { levels } = this.props;
    return levels && levels.length === (i + 1);
  };

  optionPrompt = (level) => {
    if (level.name) {
      return I18n.t('option_set.option_prompt_with_level', { level: level.name });
    }
    return I18n.t('option_set.option_prompt');
  };

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
