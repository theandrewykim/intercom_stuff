require 'intercom'

#This script will calculate the exact response time in seconds for all conversations that have been responded to by a teammate in Intercom between the given unix timestamps
#This includes all conversations that have been responded to, including conversations initiated by visitor or user auto messages.
#This does not include notes assignments, or responses by Operator.

#uses https://github.com/intercom/intercom-ruby

access_token = #ACCESS TOKEN
intercom = Intercom::Client.new(token: acces_token, handle_rate_limit: true)


start_time = #YOUR UNIX TIMESTAMP
end_time = #YOUR UNIX TIMESTAMP
proxy_array = []
intercom.admins.all.each do |admin|
  admin_object = intercom.admins.find(id: admin.id)
  convo_proxy = intercom.conversations.find_all(type: 'admin', id: admin.id)
  proxy_array << convo_proxy
end
count = 0
conversation_array = []
proxy_array.each do |proxy|
  begin
    proxy.each do |convo|
      created_at = convo.created_at.to_i
      puts "hello world"
      if created_at >= start_time || created_at <= end_time
        actual_convo = intercom.conversations.find(id: convo.id)
        conversation_array << actual_convo if actual_convo.conversation_parts.length > 1
      end
    end
  rescue Intercom::ResourceNotFound
    puts "this admin has no conversations...continuing"
  end
end


first_response_hash = Hash.new
created_at = nil
first_response_at = nil
hash_convo = nil
conversation_array.each do |conversation|
  i = 0
  response_not_found = true
  created_not_found = true
  first_response_at = " "
  created_at = " "
  if conversation.conversation_message.author.class.name == "Intercom::User" || conversation.conversation_message.author.class.name == "Intercom::Lead"
    hash_convo = conversation.id
    created_at = conversation.created_at
    until response_not_found == false || i > conversation.conversation_parts.length - 1
      if conversation.conversation_parts[i].author.class.name == "Intercom::Admin" && conversation.conversation_parts[i].part_type == "comment"
        first_response_at = conversation.conversation_parts[i].created_at
        response_not_found = false
        first_response_hash[hash_convo] = {user_message_at: created_at, reply_at: first_response_at}
      else
        i += 1
      end
    end
  else
    until (response_not_found == false && created_not_found == false) || i > conversation.conversation_parts.length - 1
      hash_convo = conversation.id
      if (conversation.conversation_parts[i].author.class.name == "Intercom::User" || conversation.conversation_parts[i].author.class.name == "Intercom::Lead")  && created_not_found == true
        created_at = conversation.conversation_parts[i].created_at
        created_not_found = false
        i += 1
      elsif conversation.conversation_parts[i].author.class.name == "Intercom::Admin" && conversation.conversation_parts[i].part_type == "comment" && created_not_found == false
        first_response_at = conversation.conversation_parts[i].created_at
        response_not_found = false
        first_response_hash[hash_convo] = {user_message_at: created_at, reply_at: first_response_at}
      else
        i += 1
      end
    end
  end
end


response_times = {}
first_response_hash.each do |conversation_id,timestamps|
  response_times[conversation_id] = timestamps[:reply_at].to_i - timestamps[:user_message_at].to_i
end





#average response time in seconds
average_response_time = response_times.sum {|conversation_id, response_time| response_time } / response_times.length
