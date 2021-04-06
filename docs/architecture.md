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
