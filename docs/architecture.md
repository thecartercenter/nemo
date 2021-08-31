# NEMO/ELMO architecture

See also the auto-generated [entity-relationship diagram](erd.pdf)
of our database schema.

## Codebase

TODO: Document some of the main files,
per the advice of <https://matklad.github.io//2021/02/06/ARCHITECTURE.md.html>.

## Input and output

This summarizes all the ways data can flow in and out of the app.
It's important to consider each of these when considering a core change.

- Form/Question
    - Create/Edit/Delete:
        - Form Builder
        - Replication
    - View:
        - Form Builder
        - SMS Guide
        - Printable Form View
        - ODK XML
        - ODK manifest
- Response/Answer
    - Create:
        - Response Form
        - SMS
        - ODK
    - Edit/Delete:
        - Response Form
    - View:
        - Response View
        - Search
        - Reports
        - Response List Key Questions (also on dashboard)
        - Dashboard Map
        - API (both legacy and OData)
        - CSV

## List of attachment types

Possible ActiveStorage attachments:

* `Operation.attachment` (export)
* `SavedUpload.file` - SavedTabularUpload (import)
* `Question.media_prompt` (shown on questions)
* `MediaObject.item` - Audio, Image, Video (submitted as answers)
* `Response.odk_xml` (raw ODK submissions)

## Options, OptionSets, and OptionNodes

For select_one or select_multiple question. May be flat or multi-level.

* OptionSet is a collection of Options
* Option should be one-to-one with OptionNode (rather vestigial, and eventually being deprecated)
* OptionNodes belong to OptionSets, and also to their own parents (they're a tree)

See also the individual models for deeper information.
