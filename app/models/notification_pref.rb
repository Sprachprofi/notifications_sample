class NotificationPref < ApplicationRecord

  OPTIN_TYPES = ['elections', 'votes', 'events', 'anything']

  before_save :remove_blank

  validates_presence_of :user_id, :provider
  
  scope :active, -> { where('provided_id IS NOT NULL') }
  scope :not_wiped, -> { where('provided_id IS NOT NULL OR waiting_confirmation_from IS NOT NULL') }
  scope :wants_msg_type, ->(msg_type) { where("(optin_type = 'anything' OR optin_type LIKE ?)", "%#{msg_type}%") }
  
  def self.optin(user_id, provider, confirmation_from, optin_type = 'anything')
    confirmation_from = ("Notifier::" + provider).constantize.standardize_preconfirmation_id(confirmation_from)
    raise "Invalid number" if not ("Notifier::" + provider).constantize.valid_preconfirmation_id?(confirmation_from)
    optin = NotificationPref.where(user_id: user_id, provider: provider).first_or_initialize
    optin.waiting_confirmation_from = confirmation_from
    optin.optin_type = optin_type
    optin.optin_history = (Time.now.to_s + " - " + "opted into receiving updates on: #{optin_type}.\n") + (optin.optin_history || "")
    optin if optin.save
  end
  
  # if this provider (e.g. Telegram) uses a different ID for sending stuff than for the confirmation, send the new ID along
  # otherwise this uses the waiting_confirmation_from ID
  def confirm_optin!(optional_id = nil)
    provided_id = optional_id || waiting_confirmation_from
    raise "Invalid number" if not ("Notifier::" + provider).constantize.valid_postconfirmation_id?(provided_id)
    self.update(provided_id: provided_id, waiting_confirmation_from: nil, optin_history: (Time.now.to_s + " - " + "confirmed optin.\n" + optin_history))
  end
  
  def confirmed?
    waiting_confirmation_from.nil? and !provided_id.nil?
  end
  
  def change_optin_type!(optin_type)
    if optin_type.blank?
      # this is an optout
      optout(self.user_id, self.provider)
    else
      self.update(optin_type: optin_type, optin_history: (Time.now.to_s + " - " + "from now on only desires updates on: #{optin_type}.\n") +  (self.optin_history || ""))
    end
  end
  
  # this will send a Telegram message to everyone who opted into Telegram messages,
  # an SMS to everyone who opted into SMS (could be the same people), and so on,
  # assuming that they have opted into messages of msg_type or 'all'.
  # expects that each kind of Notifier service is implemented as Notifier::Telegram etc.
  # and that it implements a mass_send(uids, message) method
  def self.notify(user_ids, message, msg_type)
    results = {}
    providers = NotificationPref.distinct.pluck(:provider)
    providers.each do |provider|
      uids_to_notify = NotificationPref.active.where(provider: provider).wants_msg_type(msg_type).where(user_id: user_ids).pluck(:provided_id)
      results[provider] = ("Notifier::" + provider).constantize.mass_send(uids_to_notify, message)
    end
    results
  end
  
  def self.optout(user_id, provider = 'all')
    to_opt_out = NotificationPref.where(user_id: user_id)
    to_opt_out = to_opt_out.where(provider: provider) unless provider == 'all'
    to_opt_out.each do |record|
      record.provided_id = nil
      record.waiting_confirmation_from = nil
      record.optin_history = Time.now.to_s + " - " + "opted out.\n" + record.optin_history
      record.save
    end
    to_opt_out.count
  end
  
  # optout_through_provider('Telegram', chat_id)  would remove the user to extend they have to opt in through our app afresh
  # optout_through_provider('Telegram', chat_id, 'Sprachprofi') would still allow a user called Sprachprofi to re-activate the subscription through the bot (it remains in unconfirmed state)
  def self.optout_through_provider(provider, provided_id, for_reopt_in = nil)
    to_opt_out = NotificationPref.where(provided_id: provided_id, provider: provider).first
    if to_opt_out
      to_opt_out.provided_id = nil
      to_opt_out.waiting_confirmation_from = for_reopt_in
      to_opt_out.optin_history = Time.now.to_s + " - " + "opted out.\n" + to_opt_out.optin_history
      to_opt_out.save
    end
  end
  
  def optout!
    self.update(provided_id: nil, waiting_confirmation_from: nil, optin_history: Time.now.to_s + " - " + "opted out.\n" + record.optin_history)
  end
  
private

  def remove_blank
    self.provided_id = nil if provided_id.blank?
  end

end
