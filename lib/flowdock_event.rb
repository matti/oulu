require 'filter/strip_html_filter'
require 'time'

class FlowdockEvent
  class UnsupportedMessageError < StandardError; end
  class InvalidMessageError < StandardError; end

  include CommandViews

  attr_accessor :irc_connection, :channel, :user, :message
  @@registered_events = {}

  def initialize(irc_connection, target, user, message)
    @irc_connection = irc_connection
    @target = target
    @user = user
    @message = message
  end

  def self.register_event(command)
    @@registered_events[command.to_s] = self
  end

  def self.from_message(irc_connection, message)
    event_type = @@registered_events[message['event']]
    raise UnsupportedMessageError, "Event '#{message['event']}' is not supported" if event_type.nil?

    if message['flow']
      target = irc_connection.find_channel_by_id(message['flow'])
      return if target && !target.open?
    elsif message['to']
      target = irc_connection.find_user_by_id(message['to'])
    end

    user = irc_connection.find_user_by_id(message['user'] || message['user_id'])

    processed_message = MessageProcessor.new(message).perform
    event_type.new(irc_connection, target, user, processed_message)
  end

  def process
    text = self.render
    @irc_connection.send_reply(text)
  end

  def valid?
    raise NotImplementedError.new("You need to override valid?")
  end

  protected

  def channel?
    @target.is_a?(IrcChannel)
  end

  def user?
    @target.is_a?(User)
  end

  def team_inbox_event(integration, *description)
    description.collect do |str|
      "[#{integration}] #{str}"
    end.join("\n")
  end

  def thread_event(author, thread, *description)
    description.map do |str|
      "#{thread_header(thread)} #{author}: #{str}"
    end.join("\n")
  end

  def thread_header(thread)
    thread_title = thread["title"]
    if thread["source"]
      source = thread["source"]["name"]
      app = thread["source"]["application"]["name"]

      "[#{app} (#{source}): #{thread_title}]"
    else
      "[#{thread_title}]"
    end
  end

  def first_line(text)
    text.split(/(\\n|\\r|\n|\r)/)[0] # read text until the first (escaped) new line or carriage return
  end

  def strip_html(input)
    Filter::StripHTMLFilter.new(input).call
  end
end

# Load all events automatically
Dir[File.join(File.dirname(__FILE__), 'events', '*_event.rb')].each do |file|
  require file
end
