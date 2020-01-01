module Notifier
  class Telegram
    # waiting_confirmation_from aka preconfirmation_id is a Telegram username here
    # provided_id aka postconfirmation_id is the unique id of a Telegram chat. In case of private chats, the chat id is identical to the Telegram user id but not the username
    
    def self.listen_again
      @prev_update ||= 0
      r = make_request('getUpdates', {'timeout' => 1, 'allowed_updates' => 'message', 'offset' => (@prev_update + 1)}, 'GET', true)
      unless (r.nil? or r.body.nil? or r.body.include?('"result":[]'))  # don't even go further unless there are new messages
        new_messages = JSON.parse(r.body)
        @prev_update = new_messages['result'].last['update_id']
        new_messages['result'].each do |message|
          react_to_msg(message['message']) if message['message']
        end
      end
    end
    
    def self.mass_send(provided_ids, message, verbose = false)
      success_count = 0
      provided_ids.each_with_index do |uid, i|
        response = send_msg(uid, message)
        success_count += 1 if response == 'success'
        sleep(1) if ((i % 25) == 0)  # message 25 people at a time, not to run into limits
        # update status if it's a huge set of users and verbose is true
        puts "Sent Telegram message to #{i} of #{provided_ids.count} users" if verbose and ((i % 100) == 0)
      end
      success_count
    end
    
    def self.react_to_msg(message)
      case message['text']
      when '/start'
        if (pref = NotificationPref.where(provider: 'Telegram', waiting_confirmation_from: message['from']['username']).first)
          # user did everything correctly; confirm their opt-in
          pref.confirm_optin!(message['chat']['id'])
          send_msg(message['chat']['id'], "Hello, #{message['from']['first_name']}. You will now get DiEM25 notifications from me. If you no longer want notifications, write /stop")
        elsif NotificationPref.where(provided_id: message['chat']['id']).first
          # user was already subscribed
          send_msg(message['chat']['id'], "You are currently subscribed to receive DiEM25 notifications from me. If you no longer want notifications, write /stop")
        else
          # having trouble linking this Telegram user to any DiEM25 user
          send_msg(message['chat']['id'], "I'm having trouble matching you to any DiEM25 profile. Please go to the Members Area's notifications center, " +
            "enter your Telegram name (#{message['from']['username']}) there, click Save and then come back to this chat and type /start again in order to confirm.")
        end
      when '/stop'
        NotificationPref.optout_through_provider('Telegram', message['chat']['id'], message['from']['username'])
        send_msg(message['chat']['id'], "Bye, #{message['from']['first_name']}. You will no longer get DiEM25 notifications from me. To start them again, write /start")
      else 
        send_msg(message['chat']['id'], "Sorry, I'm a very stupid bot and the only commands I know are /start and /stop.") if message['chat']['type'] == 'private'
      end
    end
    
    def self.send_msg(uid, message)
      status = 'waiting'
      if valid_postconfirmation_id?(uid)
        begin
          response = make_request('sendMessage', {chat_id: uid, text: message}, 'POST')
          status =  (response == true) ? 'success' : 'error'
        rescue 
          status = 'error'
        end
      else
        status = 'bad number'
      end
      status
    end
    
    # help users to provide good input by ensuring that Telegram user names are always spelled the same way
    def self.standardize_preconfirmation_id(username)
      username.strip.delete_prefix('@')
    end

    # tests whether the phone number has the expected format
    def self.valid_postconfirmation_id?(uid)
      !uid.blank?
    end
   
    # to match expected class structure
    def self.valid_preconfirmation_id?(uid)
      valid_postconfirmation_id?(uid)
    end
    
    
 private

    def self.make_request(relative_url, params, req_type = 'GET', show_full_response = false)
      if not Rails.env.test? 
        raise "You must provide a Telegram bot key in the credentials if you're going to use the Telegram API" unless Rails.application.credentials.telegram_bot_key
        conn = Faraday.new(:url => 'https://api.telegram.org/bot' + Rails.application.credentials.telegram_bot_key + '/')

        if req_type == 'POST'
          response = conn.post do |req|
            req.url (relative_url)
            req.headers['Content-Type'] = 'application/json'
            req.body = params.to_json
          end
        elsif req_type == 'GET'
          response = conn.get do |req|
            req.url (relative_url)
            req.headers['Content-Type'] = 'application/json'
            req.body = params.to_json
          end
         end
        (response.status == 200 and not show_full_response) ? true : response
      else
        true
      end
    end
   
  end
end
