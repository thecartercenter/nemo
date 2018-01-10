class ConditionFormField extends React.Component {

  constructor(props) {
    super();
    this.getFieldData = this.getFieldData.bind(this);
    this.updateFieldData = this.updateFieldData.bind(this);
    this.formatRefQingOptions = this.formatRefQingOptions.bind(this);
    this.buildUrl = this.buildUrl.bind(this);
    this.buildValueProps = this.buildValueProps.bind(this);
    this.deleteCondition = this.deleteCondition.bind(this);
    this.state = props;
  }

  updateFieldData(refQingId) {
    this.getFieldData(refQingId);
  }

  getFieldData(refQingId) {
    ELMO.app.loading(true);
    var self = this;
    var url = this.buildUrl(refQingId);
    $.ajax(url)
      .done(function(response) {
          // Need to put this before we set state because setting state may trigger a new one.
          ELMO.app.loading(false);

          // We set option node ID to null since the new ref_qing may have a new option set.
          self.setState(Object.assign(response, {option_node_id: null}));
        })
        .fail(function(jqXHR, exception) {
          ELMO.app.loading(false);
          console.log(exception);
        });
  }

  buildUrl(refQingId) {
    var url = `${ELMO.app.url_builder.build('questionings', 'condition-form')}?condition_id=${this.state.id}&ref_qing_id=${refQingId}&form_id=${this.state.form_id}`
    if (this.state.conditionable_id) {
      url += '&conditionable_id=' + this.state.conditionable_id;
    }
    return url;
  }

  formatRefQingOptions(reference_qing_options) {
    return reference_qing_options.map(function(o){
      return {id: o.id, name: `${o.full_dotted_rank}. ${o.code}`, key: o.id};
    });
  }

  deleteCondition() {
    this.setState({destroy: true})
  }

  buildValueProps(name_prefix, id_prefix) {
    if (this.state.option_set_id != null) {
      return {
        type: "cascading_select",
        name_prefix: name_prefix,
        for: `${id_prefix}_value`, //not a mistake; the for is for value; the others are for selects
        id: `${id_prefix}_option_node_ids_`,
        key: `${id_prefix}_option_node_ids_`,
        option_set_id: this.state.option_set_id,
        option_node_id: this.state.option_node_id,
        label: I18n.t('activerecord.attributes.condition.value')
      }
    } else {
      return {
        type: "text",
        name: `${name_prefix}[value]`,
        for: `${id_prefix}_value`,
        id: `${id_prefix}_value`,
        key: `${id_prefix}_value`,
        value: this.state.value ? this.state.value : "",
        label: I18n.t('activerecord.attributes.condition.value')
      }
    }
  }

  render() {
    let name_prefix = this.state.name_prefix + `[${this.state.index}]`;
    let id_prefix = name_prefix.replace(/[\[\]]/g, '_');
    let condition_field_props = {
      type: "hidden",
      name: `${name_prefix}[id]`,
      id: `${id_prefix}_id`,
      key: `${id_prefix}_id`,
      value: this.state.id ? this.state.id : ""
    };
    let ref_qing_field_props = {
      type: "select",
      name: `${name_prefix}[ref_qing_id]`,
      id: `${id_prefix}_ref_qing_id`,
      for: `${id_prefix}_ref_qing_id`,
      key: `${id_prefix}_ref_qing_id`,
      value: this.state.ref_qing_id ? this.state.ref_qing_id : "",
      label: I18n.t('activerecord.attributes.condition.ref_qing_id'),
      options: this.formatRefQingOptions(this.state.refable_qings),
      changeFunc: this.updateFieldData
    };
    let operator_field_props = {
      type: "select",
      name: `${name_prefix}[op]`,
      id: `${id_prefix}_op`,
      for: `${id_prefix}_op`,
      key: `${id_prefix}_op`,
      value: this.state.op ? this.state.op : "",
      label: I18n.t('activerecord.attributes.condition.op'),
      options: this.state.operator_options
    };
    let destroy_field_props = {
      type: "hidden",
      name: `${name_prefix}[_destroy]`,
      id: `${id_prefix}__destroy`,
      key: `${id_prefix}__destroy`,
      value: this.state.destroy ? "1" : "0",
    }
    let value_field_props = this.buildValueProps(name_prefix, id_prefix);
    if (this.state.destroy === true) {
      if (this.state.id) {
        return (
          <div className="condition-fields" style={{display: none}}>
            <input {...condition_field_props} />
            <input {...destroy_field_props} />
          </div>
        )
      } else {
        return null;
      }
    } else {
      return (
        <div className="condition-fields">
          <a className="action-link" onClick={this.deleteCondition}><i className="fa fa-trash-o"></i></a>
          <input {...condition_field_props}/>
          <FormField {...ref_qing_field_props} />
          <FormField {...operator_field_props} />
          <FormField {...value_field_props} />
        </div>
      );
    }
  }
}
