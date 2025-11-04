/**
 * Real-Time Validation Component
 * 
 * Displays real-time validation feedback as responses are validated.
 * Can be used inline in response forms or as a notification widget.
 */

import React from 'react';
import PropTypes from 'prop-types';

class RealTimeValidation extends React.Component {
  static propTypes = {
    responseId: PropTypes.string.isRequired,
    validationResults: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        ruleName: PropTypes.string.isRequired,
        ruleType: PropTypes.string.isRequired,
        confidence: PropTypes.number.isRequired,
        passed: PropTypes.bool.isRequired,
        issues: PropTypes.arrayOf(PropTypes.string),
        suggestions: PropTypes.arrayOf(PropTypes.string),
        explanation: PropTypes.string,
      })
    ),
    onValidate: PropTypes.func,
    autoValidate: PropTypes.bool,
    showDetails: PropTypes.bool,
  };

  static defaultProps = {
    validationResults: [],
    onValidate: null,
    autoValidate: false,
    showDetails: true,
  };

  constructor(props) {
    super(props);
    this.state = {
      isValidating: false,
      lastValidated: null,
      expandedRules: new Set(),
    };
    this.validationInterval = null;
  }

  componentDidMount() {
    if (this.props.autoValidate && this.props.onValidate) {
      this.startAutoValidation();
    }
  }

  componentWillUnmount() {
    this.stopAutoValidation();
  }

  startAutoValidation = () => {
    // Validate every 30 seconds
    this.validationInterval = setInterval(() => {
      if (this.props.onValidate && !this.state.isValidating) {
        this.handleValidate();
      }
    }, 30000);
  };

  stopAutoValidation = () => {
    if (this.validationInterval) {
      clearInterval(this.validationInterval);
      this.validationInterval = null;
    }
  };

  handleValidate = async () => {
    if (!this.props.onValidate || this.state.isValidating) return;

    this.setState({ isValidating: true });

    try {
      await this.props.onValidate(this.props.responseId);
      this.setState({
        lastValidated: new Date(),
        isValidating: false,
      });
    } catch (error) {
      console.error('Validation error:', error);
      this.setState({ isValidating: false });
    }
  };

  toggleRuleDetails = (ruleId) => {
    this.setState((prevState) => {
      const expanded = new Set(prevState.expandedRules);
      if (expanded.has(ruleId)) {
        expanded.delete(ruleId);
      } else {
        expanded.add(ruleId);
      }
      return { expandedRules: expanded };
    });
  };

  getOverallStatus = () => {
    if (!this.props.validationResults || this.props.validationResults.length === 0) {
      return 'unknown';
    }

    const allPassed = this.props.validationResults.every((r) => r.passed);
    const anyFailed = this.props.validationResults.some((r) => !r.passed);

    if (allPassed) return 'passed';
    if (anyFailed) return 'failed';
    return 'warning';
  };

  render() {
    const { validationResults, showDetails } = this.props;
    const { isValidating, lastValidated, expandedRules } = this.state;
    const overallStatus = this.getOverallStatus();

    return (
      <div className="real-time-validation">
        <div className="validation-header">
          <div className="validation-status">
            <span className={`status-indicator status-${overallStatus}`}>
              {overallStatus === 'passed' && '✓'}
              {overallStatus === 'failed' && '✗'}
              {overallStatus === 'warning' && '⚠'}
              {overallStatus === 'unknown' && '?'}
            </span>
            <span className="status-text">
              {overallStatus === 'passed' && I18n.t('ai_validation.all_passed')}
              {overallStatus === 'failed' && I18n.t('ai_validation.some_failed')}
              {overallStatus === 'warning' && I18n.t('ai_validation.warnings')}
              {overallStatus === 'unknown' &&
                I18n.t('ai_validation.not_validated')}
            </span>
          </div>

          <div className="validation-actions">
            {this.props.onValidate && (
              <button
                className="btn btn-sm btn-primary"
                onClick={this.handleValidate}
                disabled={isValidating}
              >
                {isValidating
                  ? I18n.t('ai_validation.validating')
                  : I18n.t('ai_validation.validate_now')}
              </button>
            )}

            {lastValidated && (
              <span className="last-validated">
                {I18n.t('ai_validation.last_validated')}:{' '}
                {lastValidated.toLocaleTimeString()}
              </span>
            )}
          </div>
        </div>

        {validationResults && validationResults.length > 0 && (
          <div className="validation-results-list">
            {validationResults.map((result) => {
              const isExpanded = expandedRules.has(result.id);
              return (
                <div
                  key={result.id}
                  className={`validation-result-item ${
                    result.passed ? 'passed' : 'failed'
                  }`}
                >
                  <div
                    className="result-header"
                    onClick={() => showDetails && this.toggleRuleDetails(result.id)}
                  >
                    <div className="result-info">
                      <span className="rule-name">{result.ruleName}</span>
                      <span className={`rule-status ${result.passed ? 'passed' : 'failed'}`}>
                        {result.passed
                          ? I18n.t('ai_validation.passed')
                          : I18n.t('ai_validation.failed')}
                      </span>
                      <span className="confidence-badge">
                        {(result.confidence * 100).toFixed(0)}%
                      </span>
                    </div>
                    {showDetails && (
                      <span className="expand-icon">
                        {isExpanded ? '▼' : '▶'}
                      </span>
                    )}
                  </div>

                  {showDetails && isExpanded && (
                    <div className="result-details">
                      {result.explanation && (
                        <div className="explanation">{result.explanation}</div>
                      )}

                      {result.issues && result.issues.length > 0 && (
                        <div className="issues">
                          <strong>{I18n.t('ai_validation.issues')}:</strong>
                          <ul>
                            {result.issues.map((issue, idx) => (
                              <li key={idx}>{issue}</li>
                            ))}
                          </ul>
                        </div>
                      )}

                      {result.suggestions && result.suggestions.length > 0 && (
                        <div className="suggestions">
                          <strong>{I18n.t('ai_validation.suggestions')}:</strong>
                          <ul>
                            {result.suggestions.map((suggestion, idx) => (
                              <li key={idx}>{suggestion}</li>
                            ))}
                          </ul>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {(!validationResults || validationResults.length === 0) && (
          <div className="no-validation-results">
            {I18n.t('ai_validation.no_validation_results')}
          </div>
        )}
      </div>
    );
  }
}

export default RealTimeValidation;
