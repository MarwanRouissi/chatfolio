class MessagesController < ApplicationController
  def index
    @messages = current_user.messages
    @message = Message.new # for form
  end
end
