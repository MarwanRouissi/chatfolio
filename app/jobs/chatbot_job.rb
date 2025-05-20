class ChatbotJob < ApplicationJob
  queue_as :default

  def perform(message)
    @message = message
    mistral_response = client.chat(messages: messages_formatted_for_mistralai)

    ai_answer = ""

    mistral_response.chat_completion.split(" ", 10).each do |chunk|
      ai_answer += "#{chunk} "
      sleep(0.1)

      message.update(ai_answer: ai_answer)
      broadcast_message(message)
    end
  end

  private

  def client
    @client ||= Langchain::LLM::MistralAI.new(
      api_key: ENV.fetch('MISTRAL_AI_API_KEY')
    )
  end

  def broadcast_message(message)
    Turbo::StreamsChannel.broadcast_update_to(
      "message_#{message.id}",
      target: "message_#{message.id}",
      partial: "messages/message",
      locals: { message: message }
    )
  end

  def messages_formatted_for_mistralai
    messages = @message.user.messages.last(3)
    format_messages(messages)
  end

  def load_profile_data
    file_path = Rails.root.join('lib', 'assets', 'my_profile.json')
    file_content = File.read(file_path)
    JSON.parse(file_content)
  rescue Errno::ENOENT => e
    Rails.logger.error("File not found: #{e.message}")
    {}
  rescue JSON::ParserError => e
    Rails.logger.error("JSON parsing error: #{e.message}")
    {}
  end

  def load_projects_data
    file_path = Rails.root.join('lib', 'assets', 'my_projects.json')
    file_content = File.read(file_path)
    JSON.parse(file_content)
  rescue Errno::ENOENT => e
    Rails.logger.error("File not found: #{e.message}")
    {}
  rescue JSON::ParserError => e
    Rails.logger.error("JSON parsing error: #{e.message}")
    {}
  end

  def format_messages(messages)
    result = []

    # Add the system message with the profile data
    result << system_message

    # Add user messages and AI answers
    messages.each do |message|
      result << user_message(message)
      result << assistant_message(message) if message.ai_answer.present?
    end

    result
  end

  def system_message
    {
      role: 'system',
      content: "#{load_profile_data['system_message']}.
      You are Marwan's assistant. You are here to answer user questions about his profile. The profile is as follows:
      #{load_profile_data}. Here are additional data about Marwan's projects: #{load_projects_data}."
    }
  end

  def user_message(message)
    { role: 'user', content: message.user_question }
  end

  def assistant_message(message)
    { role: 'assistant', content: message.ai_answer }
  end
end
