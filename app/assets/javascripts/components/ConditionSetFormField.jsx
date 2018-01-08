class ConditionSetFormField extends React.Component {
  constructor(props) {
    super();
    this.state = props;
    this.addCondition = this.addCondition.bind(this);
  }

  addCondition() {
    this.setState({conditions:
      this.state.conditions.concat([{
        refable_qings: this.state.refable_qings,
        operator_options: [],
        conditionable_id: this.state.conditionable_id
      }])
    });
  }

  render() {
    return (
      <div>
        {this.state.conditions.map((props, index) =>
          <ConditionFormField key={index} index={index} name_prefix={this.state.name_prefix} {...props}/>)}
        <button onClick={this.addCondition} type="button" className="btn">
          <i className="fa fa-plus"></i> {I18n.t("form_item.add_condition")}
        </button>
      </div>
    )
  }
}
