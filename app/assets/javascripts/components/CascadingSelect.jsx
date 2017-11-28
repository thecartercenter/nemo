class CascadingSelect extends React.Component {
  constructor(props) {
    super();
    this.getData = this.getData.bind(this);
    this.updateData = this.updateData.bind(this);
    this.buildUrl = this.buildUrl.bind(this);
    this.buildLevelProps = this.buildLevelProps.bind(this);
    this.buildLevels = this.buildLevels.bind(this);
    this.state = props;

  }
  componentWillMount() {
    this.updateData(this.props.option_node.node_id)
  }

  updateData(nodeId) {
    this.getData(nodeId);
    // this.setState({
    //   levels: [
    //     {name: "Kingdom",
    //      selected: 2,
    //      options: [
    //        {name: "Animal", id:1 },
    //        {name: "Plant", id: 2}
    //       ]
    //     },
    //     {name: "Family",
    //      selected: 3,
    //      options: [
    //        {name: "Tree", id: 3},
    //        {name: "Flower", id: 4}
    //       ]
    //     },
    //     {name: "Species",
    //      selected: null,
    //      options: [
    //        {name: "Oak", id: 5},
    //        {name: "Pine", id: 6}
    //       ]
    //     }
    //   ]
    // })
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

//move up to condition view and pass as prop?
  buildUrl(optionNodeId) {
    var url = `${ELMO.app.url_builder.build('option-sets', this.props.option_node.set_id, 'condition-form-view')}?option_node_id=${optionNodeId}`
    return url;
  }

  buildLevelProps(level) {
    return {
      type: "select",
      name: `questioning[condition_attributes][option_node_ids][]`,
      id: `questioning_condition_attributes_option_node_ids_`,
      key: `questioning_condition_attributes_option_node_ids_`,
      value: level.selected,
      options: level.options,
      changeFunc: this.updateData
    }
  }

  buildLevels() {
    let self = this;
    var result = [];
    if (this.state.levels) {
      result = this.state.levels.map(function(level) {
        return (
          <div className="level">
            <label>
              {level.name}
              <FormSelect {...self.buildLevelProps(level)} />
            </label>
          </div>
        );
      })
    }
    return result;
  }

  render() {
    return (
      <div className="cascading-selects" id="cascading-selects-1">
         {this.buildLevels()}
     </div>
   );
  }
}
