require "skypelogs/version"
require 'sqlite3'
require 'pry'

module Skypelogs
  # Only support Mac ATM
  def self.path
    File.expand_path(`ls ~/Library/Application\\ Support/Skype/**/main.db`.strip)
  end

  def self.messages(partner = nil)
    @messages ||= Messages.new(path).fetch(partner)
  end

  class Messages
    attr_reader :messages

    def initialize(path)
      @path = path
      @messages = []
    end

    def fetch(partner = nil)
      raw_messages(partner) do |message|
        @messages << Message.new(message)
      end

      @messages
    end

    private
    def db
      @db ||= SQLite3::Database.new(@path)
    end

    def raw_messages(partner = nil, &block)
      string = "SELECT author, dialog_partner, body_xml, timestamp FROM Messages"
      string += " WHERE author = '#{partner}' OR dialog_partner = '#{partner}'" if partner

      db.execute(string) do |row|
        yield(row)
      end
    end

    class Message
      def initialize(raw)
        @raw = raw
      end

      def author
        @raw[0]
      end

      def dialog_partner
        @raw[1]
      end

      def body_xml
        @raw[2]
      end

      def body
        @body ||= strip_xml(body_xml)
      end

      def timestamp
        @time ||= Time.at(@raw[3])
      end
      alias_method :created_at, :timestamp

      private
      def strip_xml(html_string)
        html_string.gsub(/(<[^>]*>)|\n|\t/s, "")
      end
    end
  end
end
