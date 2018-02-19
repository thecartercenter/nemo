class ConditionSetFormField extends React.Component {
  constructor(props) {
    super();
    this.state = props;
    this.addCondition = this.addCondition.bind(this);
  }

  // If about to show the set and it's empty, add a blank one.
  componentWillReceiveProps(newProps) {
    if (!newProps.hide && this.props.hide && this.state.conditions.length == 0) {
      this.addCondition();
    }
  }

  addCondition() {
    this.setState({conditions:
      this.state.conditions.concat([{
        form_id: this.state.form_id,
        refable_qings: this.state.refable_qings,
        operator_options: [],
        conditionable_id: this.state.conditionable_id,
        conditionable_type: this.state.conditionable_type
      }])});
  }

  render() {
    return (
      <div
        className="condition-set"
        style={{display: this.props.hide ? "none" : ""}}>
        {this.state.conditions.map((props, index) => (<ConditionFormField
          hide={this.props.hide}
          index={index}
          key={index}
          name_prefix={this.state.name_prefix}
          {...props} />))}
        <a
          onClick={this.addCondition}
          tabIndex="0">
          <i className="fa fa-plus" /> 
          {" "}
          {I18n.t("form_item.add_condition")}
        </a>
      </div>
    );
  }
}
