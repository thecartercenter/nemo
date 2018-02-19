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
    this.getData(this.state.option_set_id, this.state.option_node_id);
  }

  // Refresh data if the option set is changing.
  componentWillReceiveProps(nextProps) {
    if (nextProps.option_set_id != this.state.option_set_id) {
      this.getData(nextProps.option_set_id, nextProps.option_node_id);
    }
  }

  // Refresh data if the selected node changed.
  nodeChanged(newNodeId) {
    this.getData(this.state.option_set_id, newNodeId);
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
      .fail(function(jqXHR, exception) {
        console.log(exception);
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
      name: `${this.state.name_prefix}[option_node_ids][]`,
      id: "questioning_display_conditions_attributes_option_node_ids_",
      key: "questioning_display_conditions_attributes_option_node_ids_",
      value: level.selected,
      options: level.options,
      prompt: I18n.t("option_set.choose_level", {level: level.name}),
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
