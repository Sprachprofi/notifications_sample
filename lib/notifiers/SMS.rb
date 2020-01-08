module Notifier
  class SMS
    # to use this class, you must have twilio-ruby gem and specify the three twilio_ secret variables that are specific to your account
    
    # this Notifier doesn't differentiate between preconfirmation and postconfirmation IDs; both are phone numbers.
    
    def initialize
      railse "Please include twilio-ruby in your Gemfile" unless Gem.loaded_specs.has_key?('twilio-ruby')
    end
    
    def self.client
      Twilio::REST::Client.new(Rails.application.credentials.twilio_account_sid, Rails.application.credentials.twilio_auth_token)
    end

    def self.mass_send(phone_numbers, message, verbose = false)
      success_count = 0
      phone_numbers.each_with_index do |phone, i|
        response = send_msg(phone, message)
        success_count += 1 if response == 'success'
        # update status if it's a huge set of users and verbose is true
        puts "Sent SMS to #{i} of #{phone_numbers.count} phone numbers" if verbose and ((i % 100) == 0)
      end
      success_count
    end
    
    def self.send_msg(number, message)
      status = 'waiting'
      if valid_postconfirmation_id?(number)
        begin
          self.client.messages.create(
            to: number,
            from: Rails.application.credentials.twilio_phone_number,
            body: message
          ) unless Rails.env.test?
          status = 'success'
        rescue Twilio::REST::RestError
          status = 'error'
        end
      else
        status = 'bad number'
      end
      status
    end
    
    # help users to provide good input by ensuring that phone numbers are always spelled the same way
    def self.standardize_preconfirmation_id(number)
      s = number.gsub('(0)', '') # remove national prefix not used internationally
      s = s.gsub(/[^0-9\+]*/, '')  # remove anything that isn't a number, e.g. parentheses, dashes, spaces...
      s = '+' + s[2..-1] if s[0, 2] == '00'  # use + instead of 00 for international dial-out
      s
    end

    # tests whether the phone number has the expected format
    def self.valid_postconfirmation_id?(number)
      !number.nil? and number.starts_with?('+') and (number.length > 9) and (not number.include?(' '))
    end
   
    # to match expected class structure
    def self.valid_preconfirmation_id?(number)
      valid_postconfirmation_id?(number)
    end
   
  end
end
