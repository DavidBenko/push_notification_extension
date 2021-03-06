module AP
  module PushNotificationExtension
    module PushNotification
      @@config = Hash.new
      def self.config_account(config={})
        # Merge in new attributes
        @@config = @@config.merge(config).with_indifferent_access

        # Fallbacks for missing attributes
        @@config[:gcm_api_key] = ENV['AP_PUSH_NOTIFICATIONS_GCM_API_KEY'] if @@config[:gcm_api_key].blank?
        @@config[:apple_cert] = ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT'] if @@config[:apple_cert].blank?
        @@config[:apple_cert_password] = ENV['AP_PUSH_NOTIFICATIONS_APPLE_CERT_PASSWORD'] if @@config[:apple_cert_password].blank?

        cert_valid = false

        if @@config[:apple_cert] && File.file?("#{Rails.root}/#{::AP::PushNotificationExtension::PushNotification.config[:apple_cert]}")

          APNS.pem  = "#{Rails.root}/#{::AP::PushNotificationExtension::PushNotification.config[:apple_cert]}"
          APNS.pass = ::AP::PushNotificationExtension::PushNotification.config[:apple_cert_password] unless ::AP::PushNotificationExtension::PushNotification.config[:apple_cert_password].blank?

          pem_file = File.open("#{APNS.pem}")
          pem_file_contents = pem_file.read
          unless pem_file_contents.match(/Apple Development IOS Push Services/)
            # This is for production apps/certs only.
            APNS.host = 'gateway.push.apple.com' 
          end
          pem_file.close
          APNS.port = 2195
          cert_valid = true
        end
        raise 'No push services configured!' unless cert_valid || @@config[:gcm_api_key]
      end
      
      def self.config
        @@config
      end
      
      def self.json_config
        @@json ||= ActiveSupport::JSON.decode(File.read("#{File.dirname(__FILE__)}/../../../manifest.json"))
      end
      
      def execute_push_notification(object, options = {})
        options = HashWithIndifferentAccess.new(options)
        channel = ::PushNotificationExtension::Channel.where(name: options[:channel]).first || ::PushNotificationExtension::Channel.create(name: options[:channel])
        channel.publish(options[:badge], options[:alert], options[:sound], options[:message_payload], options[:config])
      end
    end
  end
end