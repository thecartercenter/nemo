/**
 * AI Validation Results Component
 * 
 * Displays validation results in a table format with filtering and sorting capabilities.
 * Can be used to display results inline or in a modal.
 */

import React from 'react';
import PropTypes from 'prop-types';

class ValidationResults extends React.Component {
  static propTypes = {
    results: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        responseCode: PropTypes.string.isRequired,
        confidence: PropTypes.number.isRequired,
        passed: PropTypes.bool.isRequired,
        issues: PropTypes.arrayOf(PropTypes.string),
        suggestions: PropTypes.arrayOf(PropTypes.string),
        explanation: PropTypes.string,
        createdAt: PropTypes.string.isRequired,
        validationType: PropTypes.string,
      })
    ).isRequired,
    onViewResponse: PropTypes.func,
    showDetails: PropTypes.bool,
    filterable: PropTypes.bool,
    sortable: PropTypes.bool,
  };

  static defaultProps = {
    onViewResponse: null,
    showDetails: false,
    filterable: true,
    sortable: true,
  };

  constructor(props) {
    super(props);
    this.state = {
      filterStatus: 'all', // 'all', 'passed', 'failed'
      filterType: 'all',
      sortBy: 'createdAt',
      sortDirection: 'desc',
      searchTerm: '',
    };
  }

  handleFilterChange = (field, value) => {
    this.setState({ [field]: value });
  };

  handleSort = (field) => {
    this.setState((prevState) => ({
      sortBy: field,
      sortDirection:
        prevState.sortBy === field && prevState.sortDirection === 'asc'
          ? 'desc'
          : 'asc',
    }));
  };

  getFilteredAndSortedResults = () => {
    let filtered = [...this.props.results];

    // Apply filters
    if (this.state.filterStatus !== 'all') {
      filtered = filtered.filter(
        (r) => (this.state.filterStatus === 'passed') === r.passed
      );
    }

    if (this.state.filterType !== 'all') {
      filtered = filtered.filter(
        (r) => r.validationType === this.state.filterType
      );
    }

    if (this.state.searchTerm) {
      const term = this.state.searchTerm.toLowerCase();
      filtered = filtered.filter(
        (r) =>
          r.responseCode.toLowerCase().includes(term) ||
          (r.explanation && r.explanation.toLowerCase().includes(term))
      );
    }

    // Apply sorting
    filtered.sort((a, b) => {
      let aVal = a[this.state.sortBy];
      let bVal = b[this.state.sortBy];

      if (typeof aVal === 'string') {
        aVal = aVal.toLowerCase();
        bVal = bVal.toLowerCase();
      }

      if (aVal < bVal) return this.state.sortDirection === 'asc' ? -1 : 1;
      if (aVal > bVal) return this.state.sortDirection === 'asc' ? 1 : -1;
      return 0;
    });

    return filtered;
  };

  getSortIcon = (field) => {
    if (this.state.sortBy !== field) {
      return '?';
    }
    return this.state.sortDirection === 'asc' ? '?' : '?';
  };

  getUniqueValidationTypes = () => {
    const types = new Set(
      this.props.results.map((r) => r.validationType).filter(Boolean)
    );
    return Array.from(types);
  };

  render() {
    const { onViewResponse, showDetails, filterable, sortable } = this.props;
    const filteredResults = this.getFilteredAndSortedResults();

    if (!this.props.results || this.props.results.length === 0) {
      return (
        <div className="ai-validation-no-results">
          <p>{I18n.t('ai_validation.no_results')}</p>
        </div>
      );
    }

    return (
      <div className="ai-validation-results">
        {filterable && (
          <div className="validation-filters">
            <div className="filter-group">
              <label>{I18n.t('ai_validation.filter_by_status')}:</label>
              <select
                value={this.state.filterStatus}
                onChange={(e) =>
                  this.handleFilterChange('filterStatus', e.target.value)
                }
                className="form-control"
              >
                <option value="all">{I18n.t('ai_validation.all')}</option>
                <option value="passed">{I18n.t('ai_validation.passed')}</option>
                <option value="failed">{I18n.t('ai_validation.failed')}</option>
              </select>
            </div>

            {this.getUniqueValidationTypes().length > 0 && (
              <div className="filter-group">
                <label>{I18n.t('ai_validation.filter_by_type')}:</label>
                <select
                  value={this.state.filterType}
                  onChange={(e) =>
                    this.handleFilterChange('filterType', e.target.value)
                  }
                  className="form-control"
                >
                  <option value="all">{I18n.t('ai_validation.all')}</option>
                  {this.getUniqueValidationTypes().map((type) => (
                    <option key={type} value={type}>
                      {type.replace(/_/g, ' ').replace(/\b\w/g, (l) =>
                        l.toUpperCase()
                      )}
                    </option>
                  ))}
                </select>
              </div>
            )}

            <div className="filter-group">
              <label>{I18n.t('ai_validation.search')}:</label>
              <input
                type="text"
                value={this.state.searchTerm}
                onChange={(e) =>
                  this.handleFilterChange('searchTerm', e.target.value)
                }
                placeholder={I18n.t('ai_validation.search_placeholder')}
                className="form-control"
              />
            </div>

            <div className="filter-results-count">
              {I18n.t('ai_validation.showing_results', {
                count: filteredResults.length,
                total: this.props.results.length,
              })}
            </div>
          </div>
        )}

        <div className="table-responsive">
          <table className="table table-striped">
            <thead>
              <tr>
                <th
                  className={sortable ? 'sortable' : ''}
                  onClick={() => sortable && this.handleSort('responseCode')}
                >
                  {I18n.t('ai_validation.response')}
                  {sortable && this.getSortIcon('responseCode')}
                </th>
                <th
                  className={sortable ? 'sortable' : ''}
                  onClick={() => sortable && this.handleSort('confidence')}
                >
                  {I18n.t('ai_validation.confidence')}
                  {sortable && this.getSortIcon('confidence')}
                </th>
                <th
                  className={sortable ? 'sortable' : ''}
                  onClick={() => sortable && this.handleSort('passed')}
                >
                  {I18n.t('ai_validation.status')}
                  {sortable && this.getSortIcon('passed')}
                </th>
                {showDetails && (
                  <th
                    className={sortable ? 'sortable' : ''}
                    onClick={() => sortable && this.handleSort('validationType')}
                  >
                    {I18n.t('ai_validation.rule_type')}
                    {sortable && this.getSortIcon('validationType')}
                  </th>
                )}
                {showDetails && <th>{I18n.t('ai_validation.issues')}</th>}
                <th
                  className={sortable ? 'sortable' : ''}
                  onClick={() => sortable && this.handleSort('createdAt')}
                >
                  {I18n.t('ai_validation.created_at')}
                  {sortable && this.getSortIcon('createdAt')}
                </th>
                {onViewResponse && <th>{I18n.t('ai_validation.actions')}</th>}
              </tr>
            </thead>
            <tbody>
              {filteredResults.length === 0 ? (
                <tr>
                  <td colSpan={showDetails ? 7 : 5} className="text-center">
                    {I18n.t('ai_validation.no_filtered_results')}
                  </td>
                </tr>
              ) : (
                filteredResults.map((result) => (
                  <tr key={result.id}>
                    <td>{result.responseCode}</td>
                    <td>
                      <div className="confidence-bar">
                        <div
                          className="confidence-fill"
                          style={{
                            width: `${(result.confidence * 100).toFixed(0)}%`,
                          }}
                        />
                        <span className="confidence-text">
                          {(result.confidence * 100).toFixed(0)}%
                        </span>
                      </div>
                    </td>
                    <td>
                      <span
                        className={`status-badge ${
                          result.passed ? 'status-success' : 'status-danger'
                        }`}
                      >
                        {result.passed
                          ? I18n.t('ai_validation.passed')
                          : I18n.t('ai_validation.failed')}
                      </span>
                    </td>
                    {showDetails && (
                      <td>
                        {result.validationType
                          ? result.validationType
                              .replace(/_/g, ' ')
                              .replace(/\b\w/g, (l) => l.toUpperCase())
                          : '-'}
                      </td>
                    )}
                    {showDetails && (
                      <td>
                        {result.issues && result.issues.length > 0 ? (
                          <span className="badge badge-warning">
                            {result.issues.length}
                          </span>
                        ) : (
                          <span className="text-muted">-</span>
                        )}
                      </td>
                    )}
                    <td>{new Date(result.createdAt).toLocaleString()}</td>
                    {onViewResponse && (
                      <td>
                        <button
                          className="btn btn-sm btn-outline-primary"
                          onClick={() => onViewResponse(result)}
                        >
                          {I18n.t('ai_validation.view')}
                        </button>
                      </td>
                    )}
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    );
  }
}

export default ValidationResults;
