import React from "react";
import PropTypes from "prop-types";

import FormSelect from "./FormSelect";

class CascadingSelect extends React.Component {
  constructor(props) {
    super();
    this.nodeChanged = this.nodeChanged.bind(this);
    this.buildUrl = this.buildUrl.bind(this);
    this.buildLevelProps = this.buildLevelProps.bind(this);
    this.buildLevels = this.buildLevels.bind(this);
    this.isLastLevel = this.isLastLevel.bind(this);
    this.state = props;
  }

  // Refresh data on mount.
  componentDidMount() {
    this.getData(this.state.optionSetId, this.state.optionNodeId);
  }

  // Refresh data if the option set is changing.
  componentWillReceiveProps(nextProps) {
    if (nextProps.optionSetId !== this.state.optionSetId) {
      this.getData(nextProps.optionSetId, nextProps.optionNodeId);
    }
  }

  // Refresh data if the selected node changed.
  nodeChanged(newNodeId) {
    this.getData(this.state.optionSetId, newNodeId);
  }

  // Fetches data to populate the control. nodeId may be null if there is no node selected.
  getData(setId, nodeId) {
    ELMO.app.loading(true);
    let self = this;
    let url = this.buildUrl(setId, nodeId);
    $.ajax(url)
      .done(function(response) {
        self.setState(response);
      })
      .always(function() {
        ELMO.app.loading(false);
      });
  }

  buildUrl(setId, nodeId) {
    return `${ELMO.app.url_builder.build("option-sets", setId, "condition-form-view")}?node_id=${nodeId}`;
  }

  buildLevelProps(level, isLastLevel) {
    return {
      type: "select",
      name: `${this.state.namePrefix}[option_node_ids][]`,
      key: "display_conditions_attributes_option_node_ids_",
      value: level.selected,
      options: level.options,
      prompt: this.optionPrompt(level),
      changeFunc: isLastLevel ? null : this.nodeChanged
    };
  }

  buildLevels() {
    let self = this;
    let result = [];
    if (this.state.levels) {
      result = this.state.levels.map(function(level, i) {
        return (
          <div
            className="level"
            key={level.name}>
            <FormSelect {...self.buildLevelProps(level, self.isLastLevel(i))} />
          </div>
        );
      });
    }
    return result;
  }

  isLastLevel(i) {
    return this.state.levels && this.state.levels.length === (i + 1);
  }

  optionPrompt(level) {
    if (level.name) {
      return I18n.t("option_set.option_prompt_with_level", {level: level.name});
    } else {
      return I18n.t("option_set.option_prompt");
    }
  }

  render() {
    return (
      <div
        className="cascading-selects"
        id="cascading-selects-1">
        {this.buildLevels()}
      </div>
    );
  }
}

CascadingSelect.propTypes = {
  optionNodeId: PropTypes.string,
  optionSetId: PropTypes.string.isRequired
};

CascadingSelect.defaultProps = {
  optionNodeId: null
};

export default CascadingSelect;
