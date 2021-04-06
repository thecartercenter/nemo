# NEMO/ELMO architecture

See also the auto-generated [entity-relationship diagram](erd.pdf) of our database schema.

## Codebase

TODO: Document some of the main files,
per the advice of <https://matklad.github.io//2021/02/06/ARCHITECTURE.md.html>.

## List of attachment types

Possible ActiveStorage attachments:

* `Operation.attachment` (export)
* `SavedUpload.file` - SavedTabularUpload (import)
* `Question.media_prompt` (shown on questions)
* `MediaObject.item` - Audio, Image, Video (submitted as answers)
* `Response.odk_xml` (raw ODK submissions)
