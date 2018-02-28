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
        formId: this.state.formId,
        refableQings: this.state.refableQings,
        operatorOptions: [],
        conditionableId: this.state.conditionableId,
        conditionableType: this.state.conditionableType
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
          namePrefix={this.state.namePrefix}
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

ConditionSetFormField.propTypes = {
  hide: React.PropTypes.bool.isRequired
};
