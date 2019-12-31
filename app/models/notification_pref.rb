class NotificationPref < ApplicationRecord

  before_save :remove_blank

  validates_presence_of :user_id, :provider
  
  scope :active, -> { where('provider_id IS NOT NULL') }
  scope :wants_msg_type, ->(msg_type) { where("(optin_type = 'all' OR optin_type LIKE ?)", "%#{msg_type}%") }
  
  def self.optin(user_id, provider, confirmation_from, optin_type = 'all')
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
    provider_id = optional_id || waiting_confirmation_from
    raise "Invalid number" if not ("Notifier::" + provider).constantize.valid_postconfirmation_id?(provider_id)
    self.update(provider_id: provider_id, waiting_confirmation_from: nil, optin_history: (Time.now.to_s + " - " + "confirmed optin.\n" + optin_history))
  end
  
  def confirmed?
    waiting_confirmation_from.nil? and !provider_id.nil?
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
      uids_to_notify = NotificationPref.active.where(provider: provider).wants_msg_type(msg_type).where(user_id: user_ids).pluck(:provider_id)
      results[provider] = ("Notifier::" + provider).constantize.mass_send(uids_to_notify, message)
    end
    results
  end
  
  def self.optout(user_id, provider = 'all')
    to_opt_out = NotificationPref.where(user_id: user_id)
    to_opt_out = to_opt_out.where(provider: provider) unless provider == 'all'
    to_opt_out.each do |record|
      record.provider_id = nil
      record.waiting_confirmation_from = nil
      record.optin_history = Time.now.to_s + " - " + "opted out.\n" + record.optin_history
      record.save
    end
    to_opt_out.count
  end
  
  def optout!
    self.update(provider_id: nil, waiting_confirmation_from: nil, optin_history: Time.now.to_s + " - " + "opted out.\n" + record.optin_history)
  end
  
private

  def remove_blank
    self.provider_id = nil if provider_id.blank?
  end

end
