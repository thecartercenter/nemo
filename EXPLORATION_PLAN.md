# NEMO Codebase Exploration & Build Plan

## Overview
NEMO is a mobile data collection and analysis web application (version 15.1) built with:
- **Backend**: Ruby on Rails 8.0
- **Frontend**: React 16.x + Backbone.js
- **Database**: PostgreSQL
- **Key Features**: Form building, data collection (web/ODK/SMS), reporting, analytics, user management

## Current State Analysis

### ✅ Fully Implemented Features
1. **Search System** (`SearchService`, `SearchController`)
   - Full-text search across responses, forms, users, reports, comments
   - Advanced filtering and sorting
   - Autocomplete suggestions
   - Well-structured service layer

2. **Analytics Dashboard** (`AnalyticsController`)
   - Response trends
   - Form performance metrics
   - User activity tracking
   - Geographic distribution
   - Completion rates
   - Response sources breakdown

3. **Core Data Collection**
   - Forms, Questions, Responses
   - Multiple input methods (Web, ODK, SMS)
   - Comments and Annotations
   - Workflows and Approvals

### 🚧 Partially Implemented Features

#### AI Validation System
**Status**: Infrastructure exists but incomplete

**What Exists**:
- `AiValidationRule` model with 8 rule types
- `AiValidationResult` model for storing results
- `AiValidationService` with batch validation, reporting, suggestions
- `AiValidationController` with full CRUD operations
- `AiValidationJob` for background processing

**What's Missing**:
- ❌ Routes not configured (just added)
- ❌ Mock AI implementation (`call_ai_model` returns random data)
- ❌ No actual AI service integration (OpenAI/Anthropic)
- ❌ Frontend React components
- ❌ Views/ERB templates
- ❌ Tests

**Rule Types Available**:
1. `data_quality` - Check for spelling, formatting issues
2. `anomaly_detection` - Detect unusual patterns
3. `consistency_check` - Find contradictions
4. `completeness_check` - Verify required fields
5. `format_validation` - Validate data formats
6. `business_logic` - Custom business rules
7. `duplicate_detection` - Find similar responses
8. `outlier_detection` - Statistical outliers

## Build Opportunities

### Priority 1: Complete AI Validation Feature

#### 1.1 Add Routes ✅ (COMPLETED)
- Added routes for AI validation rules
- Includes toggle, test, batch validation, reporting endpoints

#### 1.2 Implement Real AI Integration
**Next Steps**:
```ruby
# Create app/services/ai_providers/openai_service.rb
# Create app/services/ai_providers/anthropic_service.rb
# Create app/services/ai_providers/base_service.rb
```

**Configuration Needed**:
- Environment variables for API keys
- Model selection (GPT-3.5, GPT-4, Claude)
- Rate limiting
- Error handling
- Cost tracking

#### 1.3 Create Frontend Components
**React Components Needed**:
- `AiValidationRuleList` - Display all rules
- `AiValidationRuleForm` - Create/edit rules
- `AiValidationResults` - Show validation results
- `AiValidationDashboard` - Reports and stats
- `AiValidationSuggestions` - Rule suggestions

#### 1.4 Add Views
**ERB Templates Needed**:
- `app/views/ai_validation/index.html.erb`
- `app/views/ai_validation/show.html.erb`
- `app/views/ai_validation/new.html.erb`
- `app/views/ai_validation/edit.html.erb`
- `app/views/ai_validation/_form.html.erb`
- `app/views/ai_validation/report.html.erb`

#### 1.5 Write Tests
- Model specs
- Service specs
- Controller specs
- Integration tests
- Frontend component tests

### Priority 2: Enhance Search Feature

#### 2.1 Add Full-Text Search Indexing
- Use PostgreSQL full-text search (pg_search)
- Add searchable columns to models
- Implement relevance scoring

#### 2.2 Add Search Analytics
- Track popular searches
- Show search suggestions based on history
- Analytics for search patterns

#### 2.3 Improve Search UI
- Better autocomplete
- Search filters sidebar
- Saved searches
- Search history

### Priority 3: Analytics Enhancements

#### 3.1 Add More Analytics Metrics
- Response quality scores
- User performance metrics
- Form completion time analysis
- Geographic heatmaps
- Time-series forecasting

#### 3.2 Add Export Capabilities
- Export analytics as PDF
- Export as CSV/Excel
- Scheduled reports
- Email delivery

#### 3.3 Real-time Analytics
- WebSocket updates
- Live dashboard
- Real-time notifications

### Priority 4: New Features

#### 4.1 Data Quality Dashboard
- Overall data quality score
- Quality trends over time
- Quality by form/user/region
- Quality improvement recommendations

#### 4.2 Advanced Reporting
- Custom report builder
- Report templates
- Scheduled reports
- Report sharing

#### 4.3 API Enhancements
- GraphQL API
- Webhook system improvements
- API rate limiting
- API documentation (Swagger/OpenAPI)

#### 4.4 Mobile App Improvements
- Offline-first architecture
- Better sync mechanism
- Push notifications
- Mobile-specific features

## Technical Debt & Improvements

### Code Quality
- [ ] Fix TODOs in codebase (160+ instances)
- [ ] Remove hacky workarounds
- [ ] Improve test coverage
- [ ] Add API documentation
- [ ] Improve error handling

### Performance
- [ ] Add database indexes
- [ ] Implement caching strategy
- [ ] Optimize N+1 queries
- [ ] Add pagination everywhere
- [ ] Implement background job optimization

### Security
- [ ] Audit authentication/authorization
- [ ] Add rate limiting
- [ ] Implement CSRF protection improvements
- [ ] Add input validation
- [ ] Security headers

### Documentation
- [ ] Complete architecture.md
- [ ] API documentation
- [ ] Component documentation
- [ ] Deployment guides
- [ ] Developer onboarding guide

## Recommended Next Steps

1. **Immediate**: Complete AI Validation routes (✅ DONE)
2. **Short-term**: Implement real AI service integration
3. **Short-term**: Create basic frontend for AI validation
4. **Medium-term**: Enhance search with full-text indexing
5. **Medium-term**: Add analytics exports
6. **Long-term**: Build data quality dashboard
7. **Long-term**: Mobile app improvements

## Files Created/Modified

### Routes
- ✅ `config/routes.rb` - Added AI validation routes

### Documentation
- ✅ `EXPLORATION_PLAN.md` - This planning document

## Architecture Insights

### Key Models
- `Form` - Core form definition
- `Question` - Form questions
- `Response` - Submitted form data
- `Answer` - Individual question answers
- `User` - System users
- `Mission` - Project/mission containers
- `Report` - Various report types (STI)
- `Workflow` - Approval workflows

### Key Services
- `SearchService` - Unified search
- `AiValidationService` - AI-powered validation
- `Broadcaster` - SMS broadcasting
- `Cloning::Exporter/Importer` - Form replication

### Key Patterns
- **Mission-based**: Most resources scoped to missions
- **Ability-based**: CanCanCan for authorization
- **Decorator pattern**: Draper for view models
- **STI**: Reports use Single Table Inheritance
- **Concerns**: Shared behaviors via concerns

## Development Environment

### Setup Requirements
- Ruby (see `.ruby-version`)
- PostgreSQL
- Node.js/Yarn
- Redis (for caching/jobs)
- Memcached (optional)

### Key Commands
```bash
# Setup
bin/setup

# Run tests
bundle exec rspec
yarn test

# Start server
bin/server

# Linting
bin/lint
yarn lint:js
yarn lint:scss
```

## Questions & Considerations

1. **AI Integration**: Which AI provider to use? (OpenAI, Anthropic, local models?)
2. **Cost Management**: How to handle AI API costs?
3. **Performance**: Scale considerations for large datasets?
4. **Internationalization**: Many locales supported - ensure new features are i18n-ready
5. **Mobile**: Should we prioritize mobile experience improvements?

---

**Last Updated**: 2024
**Explored By**: AI Assistant
**Codebase Version**: 15.1
