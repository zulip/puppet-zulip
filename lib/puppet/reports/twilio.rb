require 'puppet'
require 'yaml'

begin
  require 'twiliolib'
rescue LoadError => e
  Puppet.info "You need the `twiliolib` gem to use the Twilio report"
end

Puppet::Reports.register_report(:twilio) do

  API_VERSION = '2010-04-01'

  configfile = File.join([File.dirname(Puppet.settings[:config]), "twilio.yaml"])
  raise(Puppet::ParseError, "Twilio report config file #{configfile} not readable") unless File.exist?(configfile)
  config = YAML.load_file(configfile)
  SID = config[:sid]
  TOKEN = config[:token]
  FROM = config[:from]
  TO = config[:to]

  desc <<-DESC
  Send report information to Twilio. You will need a Twilio account and token, a source phone number, and 
  a target phone number to send the SMS to.
  DESC

  def process
    if self.status == 'failed'
      Puppet.debug "Sending status for #{self.host} to #{TO}"
      account = Twilio::RestAccount.new(SID, TOKEN)
      t = {
          'From' => FROM,
          'To'   => TO,
          'Body' => "Puppet run for #{self.host} #{self.status} at #{Time.now.asctime}"
      }
      resp = account.request("/#{API_VERSION}/Accounts/#{SID}/SMS/Messages", "POST", t)
    end
  end
end
