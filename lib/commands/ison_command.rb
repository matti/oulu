class IsonCommand < Command
  register_command :ISON

  def set_data(args)
    @data = args
  end

  def valid?
    !!@data
  end

  def execute!
    available_nicks = []
    ison_nicks = @data.map{|n| n.downcase}
    if !authenticated? and ison_nicks.include? 'nickserv'
      available_nicks << "nickserv"
    else
#      irc_connection.channels.values.each do |channel|
#        channel_nicks = channel.users.map { |u| u.nick.downcase }
#        available_nicks |= (channel_nicks & ison_nicks )
#      end
    end
    reply = render_ison(available_nicks)

    send_reply(reply)
  end
end