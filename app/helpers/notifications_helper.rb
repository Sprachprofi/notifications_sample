module NotificationsHelper

  def optin_type_checkboxes(selected = '')
    html = ""
    NotificationPref::OPTIN_TYPES.each do |type|
      html += '<div class="checkbox"><label>'
      html += check_box_tag(('optin_' + type.gsub(' ', '_')), "1", selected.include?(type))
      html += type + '</label></div>'
    end
    raw html
  end

end
