require 'forwardable'
module Houston
  APPLE_PRODUCTION_GATEWAY_URI = "apn://gateway.push.apple.com:2195"
  APPLE_PRODUCTION_FEEDBACK_URI = "apn://feedback.push.apple.com:2196"

  APPLE_DEVELOPMENT_GATEWAY_URI = "apn://gateway.sandbox.push.apple.com:2195"
  APPLE_DEVELOPMENT_FEEDBACK_URI = "apn://feedback.sandbox.push.apple.com:2196"

  class Client
    attr_accessor :gateway_uri, :feedback_uri, :certificate, :passphrase, :timeout, :connection
    extend Forwardable
    def_delegators :@connection, :open, :open?, :close, :closed?

    class << self
      def development(certificate_file_name, passphrase=nil)
        client = self.new(APPLE_DEVELOPMENT_GATEWAY_URI, APPLE_DEVELOPMENT_FEEDBACK_URI, certificate_file_name, passphrase)
        client
      end

      def production(certificate_file_name, passphrase=nil)
        client = self.new(APPLE_PRODUCTION_GATEWAY_URI, APPLE_PRODUCTION_FEEDBACK_URI, certificate_file_name, passphrase)
        client
      end
    end

    def initialize(gateway_uri, feedback_uri, certificate_file_name, passphrase)
      @gateway_uri = gateway_uri
      @feedback_uri = feedback_uri
      @certificate = File.read(certificate_file_name)
      @passphrase = passphrase
      @timeout = Float(ENV['APN_TIMEOUT'] || 0.5)
      @connection = Connection.new(@gateway_uri, @certificate, @passphrase)
    end

    def push(*notifications)
      raise('please open') if closed?
      return if notifications.empty?

      notifications.flatten!

      notifications.each_with_index do |notification, index|
        next unless notification.kind_of?(Notification)
        next if notification.sent?
        next unless notification.valid?

        notification.id = index

        @connection.write(notification.message)
        notification.mark_as_sent!

        ssl = @connection.ssl
        read_socket, write_socket = IO.select([ssl], [], [ssl], timeout)

        if (read_socket && read_socket[0])
          if error = @connection.ssl.read(6)
            command, status, index = error.unpack("ccN")
            notification.apns_error_code = status
            notification.mark_as_unsent!
            @connection.close
            @connection.open
          end
        else
          notification.apns_error_code = 0
          notification.mark_as_unsent!
        end
      end
    end

    def unregistered_devices
      devices = []

      Connection.open(@feedback_uri, @certificate, @passphrase) do |connection|
        while line = connection.read(38)
          feedback = line.unpack('N1n1H140')
          timestamp = feedback[0]
          token = feedback[2].scan(/.{0,8}/).join(' ').strip
          devices << {token: token, timestamp: timestamp} if token && timestamp
        end
      end

      devices
    end

    def devices
      unregistered_devices.collect{|device| device[:token]}
    end
  end
end
