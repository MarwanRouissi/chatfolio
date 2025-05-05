require 'json'

class ChatbotJob < ApplicationJob
  queue_as :default

  def perform(message)
    @message = message
    mistral_response = client.chat(messages: messages_formatted_for_mistralai)

    message.update(ai_answer: mistral_response.chat_completion)

    # Broadcast the updated question to the Turbo stream
    Turbo::StreamsChannel.broadcast_update_to(
      "message_#{message.id}",
      target: "message_#{message.id}",
      partial: "messages/message",
      locals: { message: message }
    )
  end

  private

  def client
    @client ||= Langchain::LLM::MistralAI.new(
      api_key: ENV.fetch('MISTRAL_AI_API_KEY')
    )
  end

  # def questions_formatted_for_mistralai
  #   file = File.read(Rails.root.join('lib', 'seeds', 'my_profile.json'))
  #   data_hash = JSON.parse(file)
  #   questions = current_user.questions
  #   result = []
  #   # Add the system message with the profile data
  #   result << {
  #     role: 'system',
  #     content: "You are Marwan's assistant. You are here to answer user questions about his profile. The profile is as follows: #{data_hash}"
  #   }
  #   questions.last(3).each do |question|
  #     result << { role: 'user', content: question.user_question }
  #     result << { role: 'assistant', content: question.ai_answer } if question.ai_answer.present?
  #   end
  #   result
  # end

  def messages_formatted_for_mistralai
    profile_data = load_profile_data
    messages = @message.user.messages.last(3)
    format_messages(profile_data, messages)
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

  def format_messages(profile_data, messages)
    result = []

    # Add the system message with the profile data
    result << system_message(profile_data)

    # Add user messages and AI answers
    messages.each do |message|
      result << user_message(message)
      result << assistant_message(message) if message.ai_answer.present?
    end

    result
  end

  def system_message(profile_data)
    {
      role: 'system',
      content: "#{profile_data['system_message']}.
      You are Marwan's assistant. You are here to answer user questions about his profile. The profile is as follows:
      #{profile_data}"
    }
  end

  def user_message(message)
    { role: 'user', content: message.user_question }
  end

  def assistant_message(message)
    { role: 'assistant', content: message.ai_answer }
  end
end
