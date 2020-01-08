class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def sample_homepage
    @my_sms_pref = NotificationPref.where(user_id: @current_user_id, provider: "SMS").not_wiped.first
    @my_telegram_pref = NotificationPref.where(user_id: @current_user_id, provider: "Telegram").not_wiped.first
    @my_viber_pref = NotificationPref.where(user_id: @current_user_id, provider: "Viber").not_wiped.first
  end
  
  def detailed_homepage
    @my_sms_pref = NotificationPref.where(user_id: @current_user_id, provider: "SMS").not_wiped.first
    @my_telegram_pref = NotificationPref.where(user_id: @current_user_id, provider: "Telegram").not_wiped.first
    @my_viber_pref = NotificationPref.where(user_id: @current_user_id, provider: "Viber").not_wiped.first
  end
  
  def send_msg
    user_ids = [1]
    NotificationPref.notify(user_ids, params[:message], params[:msg_type] || 'general')
    redirect_to :root, notice: "Notifications sent!"
  end
  
  def change_optin
    pref = NotificationPref.find(params[:id])
    pref.change_optin_type!(optin_type_params)
    redirect_to detailed_homepage_path
  end
  
  def optin
    pref = NotificationPref.optin(@current_user_id, params[:provider], params[:my_phone], optin_type_params)
    pref.confirm_optin! if pref and pref.provider == 'SMS'  # for SMS there is no need for user action to confirm
    redirect_to :root    
  end
  
  def optout
    NotificationPref.optout(@current_user_id, params[:provider])   
    redirect_to :root, alert: "You have successfully deactivated #{params[:provider]} notifications."
  end
  
  def webhook
    # receive Viber messages. NOTE: must use HTTPS and send a one-time webhook request to Viber
    if params['event'] == 'message' and params['message']['type'] == 'text'
      Notifier::Viber.react_to_msg(params)
    else
      puts "Badly-formatted webhook request? #{params}"
    end
    head :ok
  end
  
private

  def authenticate_user!
    # this is a stub, since we didn't create registrations, sessions and so on
    @current_user_id = 1
  end
  
  def optin_type_params
    optins = []
    params.each do |key, value|
      if key.starts_with?('optin_')
        optins << key[6..-1]
      end
    end
    optins.join(', ')
  end
 
end
