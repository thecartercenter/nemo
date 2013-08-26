ELMO
=========

More documentation coming soon.

Diagram of the Object Model
==============
The following link describes ELMO's object model and relations.

[Entity Relationship Diagram](docs/erd.pdf)

<!---
Ensure you have the following dependencies installed.

Ruby version 1.9.2 or higher
MySQL 5.0 or higher
Imagemagick
Then follow the steps below.

Get the source code from http://code.google.com/p/elmo/source/checkout
Install the required gems by running bundle install
Create an empty database and accompanying user for use by the app.
Copy config/database.yml.example to config/database.yml and edit this file in order to configure your database settings.
Create the database structure by running bundle exec rake db:schema:load RAILS_ENV=production
Create an administrator account by running bundle exec rake db:create_admin RAILS_ENV=production
Copy config/initializers/local_config.rb.example to config/initializers/local_config.rb and edit this file in order to configure some important app settings specific to your setup.
Start the server (how to do this will depend on your web server setup).
Open the app in a browser and login using username: super password: changeme
Change the 'super' account password to something more secure.--->



<!---
The 5 Main Features
ELMO's 5 main features are represented by the 5 icons on the home page. (To reach the home page at any time, click 'ELMO' at the top of the page. They main features are:

Manage Users: Create and edit User accounts for all people using the system.
Design Forms: Create and manipulate Forms that are used for submitting data.
Submit Data: Add data (Responses) to the system using ELMO or ODK Collect.
Review Responses: Monitor incoming Responses and check them for errors.
Report Results: Generate Reports such as tables, bar charts, and maps using the data in the system.
A Note about Permissions

Not all users are permitted to perform all the above actions. Only permitted actions will be shown on the home page and the sidebar menu.

Inline Help

When creating or editing objects such as Forms, Users, or Responses, you will find short descriptions of the various fields to be filled. Refer to these descriptions for help on specific fields.

Trying It Out

If you don't yet have access to an instance of ELMO, you can try these steps out on our demo instance at https://secure2.cceom.org (username: super, password: demo).

1. Manage Users
To create a new User, click 'Create a User' on the home page. Enter the User's information and click 'Create User'.

If you chose to show printable password instructions, the User's credentials will be displayed; otherwise you will be returned to the User listing and the User's credentials will be emailed to the provided email address.

To edit or delete an existing User, click the 'Manage Users' icon on the home page, then click the pencil or trash can icon next to the User you want to edit or delete.

2. Design Forms
To create a new Form, click 'Create a Form' on the home page. Enter the name and type for the Form and click 'Create Form'. This creates a Form with no questions.

To add questions to the Form, click 'Add Questions'. A list of all the existing questions in the system is shown. To add one or more of these existing questions to the Form, check the box next to each and then click 'Add selected Questions to Form'.

Alternatively, you can click 'Create new Question' to create an entirely new question and add it to your form.

After adding one or more Questions, you will be returned to the edit Question page, where you can then add more Questions.

Before Users can submit Responses for a Form, the Form must be 'published'. To publish a form, click the 'Design Forms' icon on the home page, then click the green up arrow next to the Form you want to publish. If only a red down arrow is present, the Form is already published. You can click the red arrow to unpublish it.

Forms cannot be edited or deleted when they are published. Unpublishing a Form should always be done carefully, as editing or deleting a Form that Users have already downloaded to a mobile phone will cause errors if a User tries to submit Responses based on it.

To edit or delete an existing Form, click the 'Design Forms' icon on the home page. Make sure the Form is not published, then click the pencil or trash can icon next to the Form you want to edit or delete. To edit or delete a specific Question, edit the Form, then click the pencil icon next to the Question you want to edit. If the Question you want to edit is also included on a separate published Form, you will only be able to edit some aspects of the Question.

3. Submit Data
To submit a Response using ELMO, choose the Form you want to fill out from the 'Submit Data' dropdown box on the home page and click 'Go'.

Fill in each answer. Required answers are marked with a red asterisk.

To edit or delete a response you have submitted, click the 'Submissions by You' link on the home page. Then click the pencil or trash can icon next to the Response you want to edit or delete. Depending on your permissions, you many not be able to edit or delete Responses that have been marked 'reviewed'.

The Place Box

The Place box on the page allows you to associate a Place with your Response. Associating a Place with a Response is beneficial because it allows the data in the Response to be displayed on a map.

You can use the Place box to search for an existing Place or to create a new Place.

To search for an existing Place, enter a search phrase (such as 'Starbucks on 5th Street, Atlanta' or 'Cestos City, Liberia' and click 'Suggest'. ELMO searches existing Places within the ELMO database, as well as Google's geocoding database. (This is the same database that is used when you type a search phrase into Google Maps.) After a few seconds, matching places will be displayed. To associate your response with one of the matches, click the radio button next to it. You can then proceed with filling out the rest of your Response.

To create a new Place, click 'Create New Place' below the Place box. A 'Create Place' page will pop up. Enter the data describing the new Place and click the 'Create Place' button at the bottom.

If you create a new Place, it will only be mappable if you enter latitude and longitude data for the place. Latitude and longitude are automatically included in Places created based on Google geocoding data.

4. Review Responses
Responses submitted with ELMO or ODK should always be "sanity checked" before they are used to generate Reports. This is to catch any inadvertent errors that could lead to distorted results.

To see all Responses in the system, click the 'Review Responses' icon on the home page. To see only responses that have not yet been reviewed, click the 'Awaiting Review' link on the home page.

To review a response, click the pencil icon next to the Response you would like to review. Look over all the Answers in the Response. When you are satisfied, click the 'Reviewed' checkbox near the top of the page, and then click 'Update Response'. The Response is now marked reviewed.

5. Report Results
Reports are the ultimate product of the ELMO system, and allow insights to be drawn from all the data collected.

To view an existing Report, choose it from the Report dropdown box on the home page and click 'Go'. The Report will be displayed based on the most recent data in the system.

To create a new Report, click 'Create a Report' on the home page. Choose the Report parameters. To preview the Report without saving it, click 'Preview'. To save the Report for future use, click 'Save'.

To edit an existing Report, choose it from the Report dropdown box on the home page and click 'Go'. Once the report is displayed, click the 'Edit This Report' link below the Report title. The Report parameters will be displayed.

--->