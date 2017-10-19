class ConditionsFormField extends React.Component {

  constructor() {
    console.log("constrcutore")
    super();

    this.name_prefix = "questioning[condition_attributes]"
    this.for_prefix = "questioning_condition_attributes"
    this.getFieldData = this.getFieldData.bind(this)
    this.updateFieldData = this.updateFieldData.bind(this)

  }

  updateFieldData(ref_qing_id) {
    console.log("updateFieldData!")
    this.setState(this.getFieldData(ref_qing_id))
  }

  getFieldData(ref_qing_id) {
    console.log("get field data! ref_qing_id:")
    console.log(ref_qing_id)
    //fake data first
    let reference_qing_data = { type: "select", options: [{id: 1, name: "One"}, {id: 2, name: "Two"}, {id: 3, name: "Three"}]}
    //let reference_qing_data = {for: "questioning_condition_attributes_ref_qing_id", label: "question", name: "questioning[condition_attributes][ref_qing_id]", id: "questioning_condition_attributes_ref_qing_id", type: "select", options: reference_qing_options}

    let operator_data = (ref_qing_id == 2) ? { type: "select", options: [{id: "A", name: "Amandla"}, {id: "B", name: "Beyonce"}]} : {type: "select", options: []}
    //let operator_data = {for: "questioning_condition_attributes_op", label: "operator", name: "questioning[condition_attributes][op]", id: "questioning_condition_attributes_op", type: "select", options: operator_options }

    let value_data = (ref_qing_id == 2) ? {type: "select", options: [{id: "D", name: "Destiny's Child"}, {id: "S", name: "Sasha Fierce"}, {id: "L", name: "Lemonade"}]} : {type: "select", options: []}
    //let value_data = {for: "questioning_condition_attributes_value" , label: "Value", name: "questioning[condition_attributes][value]" , id: "questioning_condition_attributes_value" , type: "text"}

    return {reference_qing: reference_qing_data, operator: operator_data, value: value_data}
  }

  componentWillMount() {
    console.log("component will mount")
    this.state = this.getFieldData()
  }

  render() {
    console.log("render")
    let rq = this.state ? this.state.reference_qing : this.props.reference_qing
    console.log(this.state)
    console.log("rq:" + rq.type)
    let ref_qing_form_field = <FormField name="questioning[condition_attributes][ref_qing_id]" for="questioning_condition_attributes_ref_qing_id" label="Question TO TRANSLATE" type={rq.type} options={rq.options} id="questioning_condition_attributes_ref_qing_id" key="questioning_condition_attributes_ref_qing_id" changeFunc={this.updateFieldData}/>
    let o = this.state ? this.state.operator : this.props.operator
    let operator_form_field = <FormField name="questioning[condition_attributes][op]" for="questioning_condition_attributes_op" label="Operator TO TRANSLATE" type={o.type} options={o.options} id="questioning_condition_attributes_op" key="questioning_condition_attributes_op"/>
    let v = this.state ? this.state.value : this.props.value
    let value_form_field =  <FormField name="questioning[condition_attributes][value]" for="questioning_condition_attributes_value" label="Value TO TRANSLATE" type={v.type} id="questioning_condition_attributes_value" key="questioning_condition_attributes_value" options={v.options}/>
    let fields = [ref_qing_form_field, operator_form_field, value_form_field]
    return <div>{fields}</div>
  }
}
