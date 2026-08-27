// The package exports this client entrypoint, but the repo's older ESLint resolver cannot follow it.
// eslint-disable-next-line import/no-unresolved
import ReactOnRails from 'react-on-rails/client';

import UserAssignmentForm from '../ror_components/UserAssignmentForm';

ReactOnRails.register({ UserAssignmentForm });
