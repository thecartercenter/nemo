import React from "react";
import PropTypes from "prop-types";

import ConditionValueField from "./ConditionValueField";
import FormSelect from "./FormSelect";

class ConditionFormField extends React.Component {
  constructor(props) {
    super();
    this.getFieldData = this.getFieldData.bind(this);
    this.updateFieldData = this.updateFieldData.bind(this);
    this.formatRefQingOptions = this.formatRefQingOptions.bind(this);
    this.buildUrl = this.buildUrl.bind(this);
    this.buildValueProps = this.buildValueProps.bind(this);
    this.handleRemoveClick = this.handleRemoveClick.bind(this);
    this.state = props;
  }

  updateFieldData(refQingId) {
    this.getFieldData(refQingId);
  }

  getFieldData(refQingId) {
    ELMO.app.loading(true);
    let self = this;
    let url = this.buildUrl(refQingId);
    $.ajax(url)
      .done(function(response) {
        // Need to put this before we set state because setting state may trigger a new one.
        ELMO.app.loading(false);

        // We set option node ID to null since the new refQing may have a new option set.
        self.setState(Object.assign(response, {optionNodeId: null}));
      })
      .fail(function(jqXHR, exception) {
        ELMO.app.loading(false);
      });
  }

  buildUrl(refQingId) {
    let url = `${ELMO.app.url_builder.build("form-items", "condition-form")}?`;
    url += `condition_id=${this.state.id || ""}&ref_qing_id=${refQingId}&form_id=${this.state.formId}`;
    if (this.state.conditionableId) {
      url += "&conditionable_id=" + this.state.conditionableId;
      url += "&conditionable_type=" + this.state.conditionableType;
    }
    return url;
  }

  formatRefQingOptions(refQingOptions) {
    return refQingOptions.map(function(o) {
      return {id: o.id, name: `${o.fullDottedRank}. ${o.code}`, key: o.id};
    });
  }

  handleRemoveClick() {
    this.setState({remove: true});
  }

  buildValueProps(namePrefix, idPrefix) {
    if (this.state.optionSetId) {
      return {
        type: "cascading_select",
        namePrefix: namePrefix,
        for: `${idPrefix}_value`, // Not a mistake; the for is for value; the others are for selects
        id: `${idPrefix}_option_node_ids_`,
        key: `${idPrefix}_option_node_ids_`,
        optionSetId: this.state.optionSetId,
        optionNodeId: this.state.optionNodeId,
      };
    } else {
      return {
        type: "text",
        name: `${namePrefix}[value]`,
        for: `${idPrefix}_value`,
        id: `${idPrefix}_value`,
        key: `${idPrefix}_value`,
        value: this.state.value ? this.state.value : "",
      };
    }
  }

  shouldDestroy() {
    return this.state.remove || this.props.hide;
  }

  render() {
    let namePrefix = this.state.namePrefix + `[${this.state.index}]`;
    let idPrefix = namePrefix.replace(/[[\]]/g, "_");
    let idFieldProps = {
      type: "hidden",
      name: `${namePrefix}[id]`,
      id: `${idPrefix}_id`,
      key: `${idPrefix}_id`,
      value: this.state.id ? this.state.id : ""
    };
    let refQingFieldProps = {
      name: `${namePrefix}[ref_qing_id]`,
      key: `${idPrefix}_ref_qing_id`,
      value: this.state.refQingId ? this.state.refQingId : "",
      options: this.formatRefQingOptions(this.state.refableQings),
      prompt: I18n.t("condition.ref_qing_prompt"),
      changeFunc: this.updateFieldData
    };
    let operatorFieldProps = {
      name: `${namePrefix}[op]`,
      key: `${idPrefix}_op`,
      value: this.state.op ? this.state.op : "",
      options: this.state.operatorOptions,
      includeBlank: false
    };
    let destroyFieldProps = {
      type: "hidden",
      name: `${namePrefix}[_destroy]`,
      id: `${idPrefix}__destroy`,
      key: `${idPrefix}__destroy`,
      value: this.shouldDestroy() ? "1" : "0",
    };
    let valueFieldProps = this.buildValueProps(namePrefix, idPrefix);

    return (
      <div
        className="condition-fields"
        style={{display: this.shouldDestroy() ? "none" : ""}}>
        <input {...idFieldProps} />
        <input {...destroyFieldProps} />
        <FormSelect {...refQingFieldProps} />
        <FormSelect {...operatorFieldProps} />
        <div className="condition-value">
          <ConditionValueField {...valueFieldProps} />
        </div>
        <div className="condition-remove">
          <a onClick={this.handleRemoveClick}>
            <i className="fa fa-close" />
          </a>
        </div>
      </div>
    );
  }
}

ConditionFormField.propTypes = {
  hide: PropTypes.bool.isRequired
};

export default ConditionFormField;
