module Notifier
  class Viber
    # waiting_confirmation_from aka preconfirmation_id is a Viber username here
    # provided_id aka postconfirmation_id is the id of a Viber user, which is unique between that user and our bot (other bots cannot reuse)
    
    def self.mass_send(provided_ids, message, verbose = false)
      success_count = 0
      provided_ids.each_with_index do |uid, i|
        response = send_msg(uid, message)
        success_count += 1 if response == 'success'
        sleep(1) if ((i % 25) == 0)  # message 25 people at a time, not to run into limits
        # update status if it's a huge set of users and verbose is true
        puts "Sent Viber message to #{i} of #{provided_ids.count} users" if verbose and ((i % 100) == 0)
      end
      success_count
    end
    
    def self.react_to_msg(message)
      txt = message['message']['text'].strip.downcase 
      if txt == '/start'
        if NotificationPref.where(provided_id: message['sender']['id']).first
          # user was already subscribed
          send_msg(message['sender']['id'], "You are currently subscribed to receive DiEM25 notifications from me. If you no longer want notifications, write /stop")
        elsif (message['sender']['name'] != 'Subscriber') and (pref = NotificationPref.find_unconfirmed('Viber', message['sender']['name'], ''))
          # user did everything correctly; confirm their opt-in
          pref.confirm_optin!(message['sender']['id'])
          send_msg(message['sender']['id'], "Hello, #{message['sender']['name']}. You will now get DiEM25 notifications from me. If you no longer want notifications, write /stop")
        else
          # having trouble linking this Viber user to any DiEM25 user
          send_msg(message['sender']['id'], "I'm having trouble matching you to any DiEM25 profile; maybe your Viber privacy settings are too strict. Which email address do you " +
            "use in order to log into DiEM25?")
        end
      elsif txt.include?("@")
        # user identifies themselves through email address because the regular flow didn't work
        pref = NotificationPref.find_unconfirmed_by_email('Viber', txt) 
        if pref
          pref.confirm_optin!(message['sender']['id'])
          send_msg(message['sender']['id'], "Thank you! You will now get DiEM25 notifications from me. If you no longer want notifications, write /stop")
        else
          # having trouble linking this Viber user to any DiEM25 user
          send_msg(message['chat']['id'], "I'm having trouble matching you to any DiEM25 profile. Please go to the https://internal.diem25.org/notifications , " +
            "enter your Viber name (#{message['from']['username']}) there, click Save and then come back to this chat and type /start again in order to confirm.")
        end        
      elsif txt == '/stop'
        NotificationPref.optout_through_provider('Viber', message['sender']['id'], message['sender']['name'])
        send_msg(message['sender']['id'], "Bye, #{message['sender']['name']}. You will no longer get DiEM25 notifications from me. To start them again, write /start")
      else 
        send_msg(message['sender']['id'], "Sorry, I'm a very stupid bot and the only commands I know are /start and /stop.")
      end
    end
  
    def self.send_msg(uid, message)
      status = 'waiting'
      if valid_postconfirmation_id?(uid)
        begin
          response = make_request('send_message', {receiver: uid, type: 'text', text: message, "sender":{ "name":"DiEM25 Notifications Bot", "avatar":"https://diem25.org/wp-content/uploads/2018/02/diem25_logo.png"}}, 'POST')
          status =  (response == true) ? 'success' : 'error'
        rescue 
          status = 'error'
        end
      else
        status = 'bad number'
      end
      status
    end
    
    # help users to provide good input by ensuring that Viber user names are always spelled the same way
    def self.standardize_preconfirmation_id(username)
      username.strip
    end

    # tests whether the id has the expected format
    def self.valid_postconfirmation_id?(uid)
      !uid.blank?
    end
   
    # to match expected class structure
    def self.valid_preconfirmation_id?(uid)
      valid_postconfirmation_id?(uid)
    end
    
    
 private

    def self.make_request(relative_url, params, req_type = 'GET', show_full_response = false)
      unless Rails.env.test? 
        raise "You must provide a Viber bot key in the credentials if you're going to use the Viber API" unless Rails.application.credentials.viber_bot_key
        conn = Faraday.new(:url => 'https://chatapi.viber.com/pa/')
		    conn.headers = { 'X-Viber-Auth-Token' => Rails.application.credentials.viber_bot_key }

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
        # We can only tell whether the request failed by the status code in the response
        (response.status == 200 and response.body.include?("status\":0,") and not show_full_response) ? true : response
      else
        true
      end
    end
   
  end
end
