10. Search
==========

Searching is a critical aspect of being able to find the information you
need. This function is available on many parts of ELMO.

10.1. Operators
---------------

Keywords are just the words you use in your search. Combining Keywords
with Operators give the parameters for a search to occur. Keywords and
Operators form Expressions.

Operators in ELMO are: **AND, OR, NOT**\ ( ! or -), **grouping**
operator (parentheses), and **phrase** operator (“”).

+----------+---------------------------------------------------------------------+
| operator |     description                                                     |
|          |                                                                     |
+==========+=====================================================================+
| AND      | default implicit operator; matches when both of its arguments match |
|          | example (with three keywords and two implicit AND operators between |
|          | them): voters ballots stations returns matches with voters AND      |
|          | ballots AND stations.                                               |
+----------+---------------------------------------------------------------------+
| OR ( \| )| Matches when any of its two arguments match.                        |
|          | example: one \| two returns matches that have one OR two            |
|          | example: “Opening Form” \| “Polling Form” returns matches that are  |
|          | that are Opening Form or Polling Form.                              |
+----------+---------------------------------------------------------------------+
| NOT      | Matches when the first argument matches, but the second one does    |
| (!=      | not. example: form != Closing returns the matches of forms that are |
| or       | NOT the Closing form example: ballot -box matches any response with |
| -)       | an answer containing the word ballot but NOT the word box.          |
+----------+---------------------------------------------------------------------+
| (… )     | Grouping parenthesis explicitly denotes the argument boundaries.    |
|          | example: (red                                                       |
+----------+---------------------------------------------------------------------+
| “…”      | Quotes match when argument Keywords match an exact phrase. example: |
|          | “The red fox jumped over the fence“ example: “Voter lines went      |
|          | outside the center and down the street“                             |
+----------+---------------------------------------------------------------------+

10.2. Qualifiers
----------------

A qualifier is a word you add to an expression to specify where to
search. For example, searching **form: observation** within the
Responses menu will return all forms with the word “observation” in
them. Another example: searching **type: long** text in the Questions
menu returns all questions of the long text type.

Available qualifiers depend on the view or menu that you are working
within. They are listed below:

**Responses menu**

+-------------+--------------------------------------------------------------+
| Qualifier   | Function                                                     |
+=============+==============================================================+
| form:       | The name of the form submitted                               |
+-------------+--------------------------------------------------------------+
| submitter:  | The name of the user that submitted the response (partial    |
|             | matches allowed                                              |
+-------------+--------------------------------------------------------------+
| submit-date | The date the response was submitted (e.g. 1985-03-22)        |
| :           |                                                              |
+-------------+--------------------------------------------------------------+
| reviewed:   | Whether the response has been marked ‘reviewed’ (1 = yes or  |
|             | 0 = no)                                                      |
+-------------+--------------------------------------------------------------+
| source:     | The medium via which the response was submitted (‘web’,      |
|             | ‘odk’, or ‘sms’)                                             |
+-------------+--------------------------------------------------------------+
| text:       | Answers to textual questions                                 |
+-------------+--------------------------------------------------------------+

**Questions menu**

+-----------+-------------------------------------------------------------------+
| Qualifier | Function                                                          |
+===========+===================================================================+
| code:     | The question code (partial matches allowed)                       |
+-----------+-------------------------------------------------------------------+
| title:    | The question title (partial matches allowed)                      |
+-----------+-------------------------------------------------------------------+
| type:     | The question type (text, long-text, integer, decimal, location,   |
|           | select-one, select-multiple, datetime, date, time)                |
+-----------+-------------------------------------------------------------------+
| tag:      | Tags applied to the question                                      |
+-----------+-------------------------------------------------------------------+

**Users menu**

+-----------+----------------------------------------------------------------+
| Qualifier | Function                                                       |
+===========+================================================================+
| name:     | The user’s full name                                           |
+-----------+----------------------------------------------------------------+
| login:    | The user’s username                                            |
+-----------+----------------------------------------------------------------+
| email:    | The user’s email address                                       |
+-----------+----------------------------------------------------------------+
| phone:    | The user’s phone number (no dashes or other punctuation, e.g.  |
|           | 1112223333                                                     |
+-----------+----------------------------------------------------------------+
| group:    | The user group that the user belongs to                        |
+-----------+----------------------------------------------------------------+

**SMS Menu**

+-----------+-------------------------------------------------------------------+
| Qualifier | Function                                                          |
+===========+===================================================================+
| content   | The message content (partial matches allowed)                     |
+-----------+-------------------------------------------------------------------+
| type:     | The message type (incoming, reply, or broadcast) (partial matches |
|           | allowed                                                           |
+-----------+-------------------------------------------------------------------+
| username  | The username of the sender or receiver (partial matches allowed)  |
+-----------+-------------------------------------------------------------------+
| name:     | The full name of the sender or receiver (partial matches allowed) |
+-----------+-------------------------------------------------------------------+
| number:   | The phone number of the sender or receiver (partial matches       |
+-----------+-------------------------------------------------------------------+
| date:     | The date the message was sent or received (e.g. 2015-01-29)       |
+-----------+-------------------------------------------------------------------+
| datetime  | The date and time the message was sent or received (use quotation |
|           | marks and 24-hr time, e.g. “2015-01-29 14:00”)                    |
+-----------+-------------------------------------------------------------------+