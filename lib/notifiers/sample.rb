module Notifier
  class Sample
    # this is an example of which methods any Notifier class needs to implement in order to work seamlessly

    # given an array of provided_ids (such as phone numbers or Facebook IDs or similar),
    # send a message to all
    # and return the number for which messaging was successful
    def self.mass_send(provided_ids, message, verbose = false)
      success_count = 0
      provided_ids.each do |id|
        status = send_msg(id, message)
        success_count += 1 if status == 'success'
      end
      success_count
    end
    
    # given a single provided_id (such as a phone number or Facebook ID or similar),
    # maybe check the format using valid_postconfirmation_id?, then 
    # send a message to them and return success in some way
    def self.send_msg(provided_id, message)
      if valid_postconfirmation_id?(provided_id)
        # pretend we were able to send
        'success'
      else
        'bad number'
      end
    end

    # if you have a way to standardize this user input (e.g. a standard way to write a phone number or Telegram name or Twitter name),
    # apply it here and return the standardized form. Otherwise return the unchanged input.    
    def self.standardize_preconfirmation_id(provided_id)
      provided_id
    end

    # check whether the provided_id (e.g. a phone number) has the expected format
    # this refers to the final provided_id, the one obtained after confirmation
    def self.valid_postconfirmation_id?(provided_id)
      provided_id.starts_with?('invalid') ? false : true
    end
   
    # same as above. Can be distinct in case there are two different IDs, 
    # one used for obtaining confirmation and one after-confirmation, as with Telegram
    def self.valid_preconfirmation_id?(provided_id)
      valid_postconfirmation_id?(provided_id)
    end
   
  end
end
