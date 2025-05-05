class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_messages, only: %i[index create]

  def index
    @message = Message.new
  end

  def create
    @message = Message.new(message_params)
    @message.user = current_user
    if @message.save
      render_message(@message)
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_messages
    @messages = current_user.messages
  end

  def render_message(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.append("messages", partial: "messages/message", locals: { message: message }),
          turbo_stream.replace("message_form", partial: "messages/form", locals: { message: Message.new })
        ]
      end
      format.html { redirect_to messages_path }
    end
  end

  def message_params
    params.require(:message).permit(:user_question)
  end
end
