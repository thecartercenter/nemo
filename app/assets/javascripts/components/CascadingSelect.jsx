class CascadingSelect extends React.Component {
  constructor(props) {
    super();
    this.getData = this.getData.bind(this);
    this.updateData = this.updateData.bind(this);
    this.buildUrl = this.buildUrl.bind(this);
    this.buildLevelProps = this.buildLevelProps.bind(this);
    this.buildLevels = this.buildLevels.bind(this);
    this.isLastLevel = this.isLastLevel.bind(this);
    this.state = props;

  }
  componentWillMount() {
    this.updateData(this.props.option_node.node_id);
  }

  updateData(nodeId) {
    this.getData(nodeId);
  }

  getData(nodeId) {
    ELMO.app.loading(true);
    var self = this;
    var url = this.buildUrl(nodeId);
    $.ajax(url)
      .done(function(response) {
          self.setState(response);
        })
        .fail(function(jqXHR, exception){
          console.log(exception);
        })
        .always(function() {
          ELMO.app.loading(false);
        });
  }

  buildUrl(optionNodeId) {
    return `${ELMO.app.url_builder.build('option-sets', this.props.option_node.set_id, 'condition-form-view')}?node_id=${optionNodeId}`;
  }

  buildLevelProps(level, isLastLevel) {
    return {
      type: "select",
      name: `questioning[display_conditions_attributes][][option_node_ids][]`,
      id: `questioning_display_conditions_attributes_option_node_ids_`,
      key: `questioning_display_conditions_attributes_option_node_ids_`,
      value: level.selected,
      options: level.options,
      changeFunc: isLastLevel ? null : this.updateData
    }
  }

  buildLevels() {
    let self = this;
    var result = [];
    if (this.state.levels) {
      result = this.state.levels.map(function(level, i) {
        return (
          <div className="level" key={level.name}>
            <label>
              {level.name}
              <FormSelect {...self.buildLevelProps(level, self.isLastLevel(i))} />
            </label>
          </div>
        );
      })
    }
    return result;
  }

  isLastLevel(i) {
    return this.state.levels && this.state.levels.length === (i + 1);
  }

  render() {
    return (
      <div className="cascading-selects" id="cascading-selects-1">
        {this.buildLevels()}
      </div>
   );
  }
}
