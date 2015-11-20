require 'dotenv'
require 'slack-ruby-client'
require 'httparty'
require 'hashie'
require 'ffaker'
require 'pry'

Dotenv.load


Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  fail 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

class Bot

  URI_REGEX = %r"((?:(?:[^ :/?#]+):)(?://(?:[^ /?#]*))(?:[^ ?#]*)(?:\?(?:[^ #]*))?(?:#(?:[^ ]*))?)"

  attr_accessor :client, :default_channel_id

  def initialize()
    @client = Slack::RealTime::Client.new
    @default_channel_id = ENV['SLACK_CHANNEL_ID']
    start
    puts "ready!"
    client.start!
  end

  def clean_message_for_speech(message)
    message.split(URI_REGEX).collect do |s|
      unless s =~ URI_REGEX
        s
      end
    end.join.gsub(',', '').gsub('/', ' ').gsub('@', '').gsub('"', '').gsub("'", '').gsub('#', '').gsub('(', '').gsub(')', '').gsub('!', '')
  end

  def start
    client.on :hello do
      puts "Successfully connected, welcome '#{client.self['name']}' to the '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com."
    end

    client.on :message do |data|
      begin
        puts data
        # if data["channel"] == channel_id
        poster = User.new(user_id: data["user"])
        # only returns the message
        created_message = Message.new(data["channel"], poster, data["text"]).message_action()
        send_message(created_message, data["channel"]) if created_message
        # client.web_client.chat_postMessage({channel: ENV['SLACK_CHANNEL_ID'], text: created_message.message, as_user: true})
      rescue StandardError => e
        puts "ERROR ERROR ERROR!"
        puts e
      end
    end

  end

  def send_message(message, channel_id)
    # puts client.inspect
    puts message
    client.web_client.chat_postMessage({channel: channel_id, text: message, as_user: true})
  end
end

class Message

  attr_accessor :channel_id, :poster, :text, :message

  def initialize(channel_id, poster, text)
    @channel_id = channel_id
    @poster = poster
    @text = text
  end

  def message_action
    if text =~ /insult/ then insult
    elsif text =~ /motivate/ then motivate
    elsif text =~ /inspire/ then inspire
    elsif text =~ /pun/ then pun
    elsif text =~ /cody/ then cody
    else
      nil
    end
  end

  def find_directed_at(gsub_out)
    who = text.gsub(gsub_out, '')
    # freaken ActiveSupport
    who.strip.length > 0 ? "#{who}: " : ''
  end

  def make_call(url)
    Hashie::Mash.new(HTTParty.get(url))
  end

  def insult
    @message = get_insult.prepend(find_directed_at('insult'))
  end

  def get_insult
    # broken
    make_call("http://pleaseinsult.me/api?severity=random").insult
  end

  def motivate
    @message = get_motivation.prepend(find_directed_at('motivate'))
  end

  def get_motivation
    #  Also Broken =(
    make_call('http://pleasemotivate.me/api').motivation
  end

  def pun
    @message = get_pun.prepend(find_directed_at('pun'))
  end

  def get_pun
    make_call("http://www.kimonolabs.com/api/2oiziu8k?apikey=a1843d6ac7111afa6ee3014e6834de0c").results.puns.sample.pun
  end

  def inspire
    @message = get_inspiration.prepend(find_directed_at('inspire'))
  end

  def get_inspiration
    make_call("http://ron-swanson-quotes.herokuapp.com/quotes").quote
  end

  def say

  end

  def cody
    @message = "cody stop being a slacker. #{get_insult}"
  end

  def travis(person, status)

  end

  def lunch

  end

end

class User

  attr_accessor :user_id, :username

  # later turn this call into a user list call that will find all the user is and names
  USER_LOOKUP = {"U04MBB34U" => "Quintin", "USLACKBOT" => "SlackBot" }

  def initialize(options = {})
    if options[:user_id]
      @user_id = options[:user_id]
      @username = USER_LOOKUP[user_id]
    end
    puts "USER"
    puts self.inspect
  end

end

Bot.new
