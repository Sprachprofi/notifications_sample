class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def sample_homepage
    @my_sms_pref = NotificationPref.where(user_id: @current_user_id, provider: "SMS").first
    @my_telegram_pref = NotificationPref.where(user_id: @current_user_id, provider: "Telegram").first
  end
  
  def send_msg
    user_ids = [1]
    NotificationPref.notify(user_ids, params[:message], 'general')
    redirect_to :root, notice: "Notifications sent!"
  end
  
  def optin
    pref = NotificationPref.optin(@current_user_id, params[:provider], params[:my_phone])
    pref.confirm_optin! if pref and pref.provider == 'SMS'  # for SMS there is no need for user action to confirm
    redirect_to :root    
  end
  
  def optout
    NotificationPref.optout(@current_user_id, params[:provider])   
    redirect_to :root, alert: "You have successfully deactivated #{params[:provider]} notifications."
  end
  
  def webhook
    # do whatever
  end
  
private

  def authenticate_user!
    # this is a stub, since we didn't create registrations, sessions and so on
    @current_user_id = 1
  end
 
end
