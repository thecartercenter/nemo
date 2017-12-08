13. Information for Administrators
==================================

| More in-depth information on the following topics is provided in this
  section:
| \* SMS Gateways (FrontlineSMS/Twilio)
| \* Standards and Data Integrity

13.1. FrontlineSMS gateway setup
--------------------------------

You can turn your Android smartphone or tablet into a gateway using the
FrontlineSync app and a FrontlineCloud account. Check out Frontline’s
documentation for the full details (http://www.frontlinesms.com/).

Before entering your settings on ELMO, you will need to set things up on
FrontlineCloud in order to obtain the Frontline API key.

| **I. FrontlineCloud**
| Logging into your FrontlineCloud account, establish the following
  settings:

1. Choose **Connect to a Mobile Network**
2. Select **FrontlineSync**
3. Select the **Activity** menu
4. Create a **New Activity**
5. Select **Forward to URL**

   1. Name your Activity: *this can be your mission name or whatever you
      want*
   2. Select **“All inbound SMS”** from the toggle choices
   3. Target URL is the URL generated the Incoming SMS Token in the
      Settings panel of the ELMO Mission
   4. HTTP Method: POST
   5. Create Keys:

+------------------+-------------------------------+
| **from**         | **${trigger.sourceNumber}**   |
+==================+===============================+
| frontlinecloud   | 1                             |
+------------------+-------------------------------+
| sent\_at         | ${trigger.date.time}          |
+------------------+-------------------------------+
| body             | ${trigger.text}               |
+------------------+-------------------------------+

.. figure:: frontline-fwd-to-url-edited-with-numbers.png
   :alt: frontline fwd to url edited with numbers

   frontline fwd to url edited with numbers

If an API is automatically generated for you, terrific! But if not, here
are the steps you need to take in order to set up an API:

1. Choose the Settings gear in the upper right of the screen
2. Select **API web services and integrations**
3. Click the **Connect a web service** button
4. Select “Connect an external web service to your workspace”
5. Name it something meaningful (e.g. “ELMO API”)

A new row will appear on the screen with an API key in the details,
beginning with “API Key:” Everything after the “:” is the API key,
remember that information for the next steps.

| **II. ELMO:**
| In ELMO, you can establish multiple incoming and outgoing SMS numbers
  on different gateway services such as Twilio or Frontline. We will
  deal with the simplest case first, a single number for SMSes. In
  settings,

1. Add the SIM card number to the **Incoming Number** field. (if adding
   more than one number, separate the numbers with a comma)
2. Then add the API code from Frontline into the **Frontline Cloud
   Settings** field
3. Set the **Default Outgoing Provider** to **FrontlineCloud**
4. Save the settings

.. figure:: frontline-on-elmo-edited.png
   :alt: frontline on elmo edited

   frontline on elmo edited

| **III. Android Device:**
| To make a Android phone or tablet into a gateway, you need to download
  and install FrontlineSync App from the Google Play store. Then, enter
  the following settings:

1. Tap on Settings in the FrontlineSync app
2. Tap **Configure Connection**
3. Enter the credentials for the FrontlineCloud activity you set up
   earlier
4. Tap the **Connect** button
5. New options will appear, now click the first two checkboxes:

   -  *Send messages using this Android*
   -  *Upload incoming messages from FrontlineSync*

6. Use the slider to set a check for outgoing messages “\ ***Every 1
   minute***\ ”
7. Click the **Update** button

A message should appear declaring success, with one more button to tap
“\ **Done! Start Using FrontlineSync**.”

    ***Note:** MAKE SURE TO USE THE DEFAULT MESSENGER APP ON THE PHONE
    —- ENCRYPTED SMS, such as What’s App, DOES NOT WORK. Look up Android
    settings help for how to make sure that your using the default
    messenger app.*

| **Some additional (troubleshooting) notes, maybe:**
| If you change settings on your FrontlineCloud after having set up your
  Android Device, you may need to enter your credentials to configure
  your connection, and make sure everything is up to date.

Also, if you set up more than one device or phone to a FrontlineCloud
account, please pay attention to the “connections to mobile networks”
settings, which is available off the gear menu located on the upper
right corner of the screen. Check with FrontlineSMS for more information
on these parameters.