class ConditionSetFormField extends React.Component {
  constructor(props) {
    super();
    this.state = props;
    this.addCondition = this.addCondition.bind(this);
  }

  addCondition() {
    this.setState({conditions:
      this.state.conditions.concat([{
        form_id: this.state.form_id,
        refable_qings: this.state.refable_qings,
        operator_options: [],
        conditionable_id: this.state.conditionable_id,
        conditionable_type: this.state.conditionable_type
      }])
    });
  }

  render() {
    return (
      <div style={{display: this.props.show ? '' : 'none'}}>
        {this.state.conditions.map((props, index) =>
          <ConditionFormField key={index} index={index} name_prefix={this.state.name_prefix} {...props}/>)}
        <button onClick={this.addCondition} type="button" className="btn">
          <i className="fa fa-plus"></i> {I18n.t("form_item.add_condition")}
        </button>
      </div>
    );
  }
}
