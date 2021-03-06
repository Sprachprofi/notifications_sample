# Notification Sample app

People rely less and less on email, so it is good to allow your users to receive important notifications through other channels if they wish.

This app demonstrates how you can do these notifications, through a platform-agnostic interface. Covers:

- Collecting your users' opt-in for one or more platforms. They can specify to receive one or more or all types of notifications.
- Confirmation step (required by some platforms)
- Allowing users to opt out of notifications for one platform or all
- Allowing users to opt in/out of different types of notifications while retaining their subscription.
- Notifying all your users, each via their preferred platform(s) and if the message is one of the types they opted into.
- Retrieving expected reach and expected cost of sending a notification.
- Recording a user's history of opting in and out, so that you can proof you had had their permission at a certain time. (Does not store personal data as per the GDPR and hence does not need to be wiped, but when you delete a user record, be sure to opt them out of notifications)
- Using the raw Telegram Bot API. This kind of bot only needs two API functions and does not need to be terribly responsive, so we're not including a gem or setting up a background listening task for this, just doing short-polling when needed.
- Using the raw Viber Bot REST API through webhooks.

## Use

Most of what you see in this project is a boilerplate Rails 6.0 app. What you want to look at is:

- `/lib/notifiers/sample.rb` - Test notifier which also explains the expected structure of these files if you plan to write one for Jabber or whatever
- `/lib/notifiers/SMS.rb` - Working notifier to send text messages to people's cellphones, via Twilio
- `/lib/notifiers/Telegram.rb` - Working notifier to send Telegram messages
- `/lib/notifiers/Viber.rb` - Working notifier to send Viber messages. Note: requires functioning webhook
- `/app/models/notification_pref.rb` - ActiveRecord model which stores all of your users' notification preferences. To send them all a message through whichever platforms available, use `NotificationPref.notify(user_ids, message, msg_type)` 
- `/spec/models/notification_pref_spec.rb` - Tests that can also be used to learn how to use the app
- `/app/controllers/notifications_controller.rb` - Sample app (use rails s) that allows you to opt in and opt out various people and send them messages. The detailed homepage does so with the ability to opt into various types of messages.

## Before running

You need to specify the `db_user` and `db_pw` for the test/dev environment in secrets.yml.enc and run the migration, then the rspec test will succeed. 
In order for the app to function, you also need to have a Twilio account and fill in `twilio_account_sid, twilio_auth_token` and `twilio_phone_number` in secrets.yml.enc.
For the Telegram messaging, you need to have a registered Telegram Bot and fill in `telegram_bot_key` in secrets.yml.enc and ensure that NotificationPref::Telegram.listen_again gets called regularly, e.g. once a minute, or call it from the console. For the Viber messaging, you need to have a registered Viber Bot and fill in `viber_bot_key` in secrets.yml.enc and [tell Viber about your webhook URL](https://developers.viber.com/docs/api/rest-bot-api/#setting-a-webhook).

## License

Code by [Judith Meyer](https://twitter.com/GermanPolyglot) for [DiEM25](https://diem25.org) and released under [GPL license](https://www.gnu.org/licenses/gpl-3.0.en.html).