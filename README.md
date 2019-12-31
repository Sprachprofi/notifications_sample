# Notification Sample app

People rely less and less on email, so it is good to allow your users to receive important notifications through other channels if they wish.

This app demonstrates how you can do these notifications, through a platform-agnostic interface. Covers:

- Collecting your users' opt-in for one or more platforms. They can specify to receive one or more or all types of notifications.
- Confirmation step (required by some platforms)
- Allowing users to opt out of notifications for one platform or all
- Notifying all your users, each via their preferred platform(s) and if the message is one of the types they opted into.
- Recording a user's history of opting in and out, so that you can proof you had had their permission at a certain time. (Does not store personal data as per the GDPR and hence does not need to be wiped, but when you delete a user record, be sure to opt them out of notifications)

## Use

Most of what you see in this project is a boilerplate Rails 6.0 app. What you want to look at is:

- `/lib/notifiers/sample.rb` - Test notifier which also explains the expected structure of these files if you plan to write one for Jabber or whatever
- `/lib/notifiers/SMS.rb` - Working notifier to send text messages to people's cellphones, via Twilio
- `/app/models/notification_pref.rb` - ActiveRecord model which stores all of your users' notification preferences. To send them all a message through whichever platforms available, use `NotificationPref.notify(user_ids, message, msg_type)` 
- `/spec/models/notification_pref_spec.rb` - Tests that can also be used to learn how to use the app
- `/app/controllers/notifications_controller.rb` - Sample app (use rails s) that allows you to opt in and opt out various people and send them messages

## Before running

You need to specify the `db_user` and `db_pw` for the test/dev environment in secrets.yml.enc and run the migration, then the rspec test will succeed. 
In order for the app to function, you also need to have a Twilio account and fill in `twilio_account_sid, twilio_auth_token` and `twilio_phone_number` in secrets.yml.enc.

## License

Code by [Judith Meyer](https://twitter.com/GermanPolyglot) for [DiEM25](https://diem25.org) and released under [GPL license](https://www.gnu.org/licenses/gpl-3.0.en.html).