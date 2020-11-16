# Project Approach to Object Destruction

Object destruction is notoriously buggy when many associations exist.

Our approach first and foremost is to enforce foreign key relationships in the database. This preserves
data integrity. But users should not be triggering foreign key errors in all but the oddest of circumstances.
Instead, we should be using ActiveRecord to either:

1. perform a cascading destroy or nullification
1. raise an ActiveRecord::DeleteRestrictionError that we handle appropriately and present a
   graceful error message

Test coverage of this should be as follows for each model:

* Test dependent destruction at the model level, one association at a time.
  See models/user_spec.rb for example.
* Test dependent destruction whether or not it is permitted by abilities. If it is not permitted,
  we test that appropriate exceptions are raised.
* Test destroy permissions in the ability specs.
* Test destruction in feature specs when destruction is an allowable action.

Such coverage does not presently exist for all models/controllers, but this is what we should be striving for
in all new development.

## DeletionError

This is an old custom error class that predates ActiveRecord::DeleteRestrictionError. We should refactor
to use the latter. This has already begun. See OptionSet, User, and ApplicationController::Crud.

## Batch Destruction

We use special classes for performing bulk destruction and returning information to the user on the
operation. See the files in `app/destroyers`. These classes all have model specs.

Historically we have faced at least one catastrophic bug with bulk destruction wherein ambiguity in the
behavior of 'select all' ('this page' vs. 'all pages') resulted in the destruction of large amounts of data.
As a result of this, we now have careful feature spec coverage for the users controller. Since
all batch destruction shares the same code, this should be sufficient to test all various combinations.
Other feature specs, such as responses and questions, cover batch destruction in a more cursory fashion.

## I18n

When we add `dependent: :restrict_with_exception` to an association, we need to remember to add
a new i18n key:

    activerecord.errors.models.#{model}.cant_delete_if_has_#{assn_name}

where `assn_name` is the name of the association on the model. See existing keys for an example.
