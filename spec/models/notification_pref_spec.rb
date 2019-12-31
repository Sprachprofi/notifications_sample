require 'rails_helper'

RSpec.describe NotificationPref, type: :model do
  
  it 'registers a user, confirms and sends an notification' do 
    pref = NotificationPref.optin(1, 'Sample', 'testID')
    expect(pref.persisted?)
    expect(pref.provider_id).to be_nil
    expect(!pref.confirmed?)
    pref.confirm_optin! 
    expect(pref.confirmed?)
    expect(pref.provider_id).to eq 'testID'
    result = NotificationPref.notify([1], "Test message", "general")
    expect(result['Sample']).to eq 1  # 1 user successfully notified
  end
  
  it 'stores a new provider_id when provided upon confirmation and sends to that one' do 
    pref = NotificationPref.optin(2, 'Sample', 'testID')
    expect(pref.provider_id).to be_nil
    pref.confirm_optin!('use_this_to_message')
    expect(pref.provider_id).to eq 'use_this_to_message'
    result = NotificationPref.notify([2], "Test message", "general")
    expect(result['Sample']).to eq 1  # 1 user successfully notified
  end
  
  it 'successfully unregisters a user and does not send further messages to them' do 
    pref = NotificationPref.optin(2, 'Sample', 'testID')
    pref.confirm_optin! 
    expect(pref.confirmed?)
    expect(NotificationPref.where(user_id: 2).first.provider_id).to eq 'testID'
    NotificationPref.optout(2, 'all')
    expect(NotificationPref.where(user_id: 2).first.provider_id).to be_nil
    result = NotificationPref.notify([2], "Test message", "general")
    expect(result['Sample']).to eq 0  # No user notified
  end
  
  it 'does not send messages to non-existent or unconfirmed users' do 
    NotificationPref.optin(3, 'Sample', 'testID')
    result = NotificationPref.notify([1, 3, 99], "Test message", "general")
    expect(result['Sample']).to eq 0  # No user notified
  end
  
  it 'raises an error if the provider_id has the wrong format' do
    expect { NotificationPref.optin(4, 'Sample', 'invalidID') }.to raise_error("Invalid number")
  end
  
  it 'does not try to deliver messages to invalid provider_ids if they accidentally wind up in the system' do
    pref = NotificationPref.optin(4, 'Sample', 'testID')
    pref.confirm_optin!
    NotificationPref.where(user_id: 4).first.update(provider_id: 'invalidID')
    result = NotificationPref.notify([4], "Test message", "general")
    expect(result['Sample']).to eq 0  # No user notified
  end
  
  it 'remembers the type of notification people opt into and sends accordingly' do 
    NotificationPref.optin(5, 'Sample', 'testID', 'free_stuff').confirm_optin!
    NotificationPref.optin(6, 'Sample', 'another_testID', 'all').confirm_optin!
    NotificationPref.optin(7, 'Sample', 'testID', 'free_stuff,bills').confirm_optin!
    user_ids = [5, 6, 7, 8]
    result = NotificationPref.notify(user_ids, "Get a freebie today by visiting our website!", "free_stuff")
    expect(result['Sample']).to eq 3
    result = NotificationPref.notify(user_ids, "Invoice #564", "bills")
    expect(result['Sample']).to eq 2
    result = NotificationPref.notify(user_ids, "New Year newsletter", "newsletter")
    expect(result['Sample']).to eq 1
  end
end
