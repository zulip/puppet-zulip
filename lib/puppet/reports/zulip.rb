require 'puppet'
require 'yaml'
require 'net/https'


Puppet::Reports.register_report(:zulip) do

  API_VERSION = '1'

  configfile = File.join([File.dirname(Puppet.settings[:config]), "zulip.yaml"])
  raise(Puppet::ParseError, "Zulip report config file #{configfile} not readable") unless File.exist?(configfile)
  config = YAML.load_file(configfile)
  ZULIP_STATUSES = Array(config[:zulip_statuses] || 'failed')

  ZULIP_TYPE = config[:type]
  ZULIP_BOTEMAIL = config[:botemail]
  ZULIP_KEY = config[:key]
  ZULIP_TO = config[:to]
  ZULIP_SUBJECT = config[:subject]
  DISABLED_FILE = File.join([File.dirname(Puppet.settings[:config]), 'zulip_disabled'])
  

  desc <<-DESC
  Send report information to Zulip.
  DESC

  def process
    # Disabled check here to ensure it is checked for every report
    disabled = File.exists?(DISABLED_FILE)
    
    if (ZULIP_STATUSES.include?(self.status) || ZULIP_STATUSES.include?('all')) && !disabled
      Puppet.debug "Sending status for #{self.host} to #{ZULIP_TO}"
      https = Net::HTTP.new('api.zulip.com','443')
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new("/v#{API_VERSION}/messages")
      request.basic_auth("#{ZULIP_BOTEMAIL}", "#{ZULIP_KEY}")

      if ZULIP_TYPE == 'stream'
        request.set_form_data({'type' => 'stream', 'to' => "#{ZULIP_TO}", 'subject' => "#{ZULIP_SUBJECT}", 'content' => "Puppet run for #{self.host} #{self.status} at #{Time.now.asctime}"})
      elsif ZULIP_TYPE == 'private'
        request.set_form_data({'type' => 'private', 'to' => "#{ZULIP_TO}",'content' => "Puppet run for #{self.host} #{self.status} at #{Time.now.asctime}"})
      end
      
      resp = https.request(request)
    end
  end
end
