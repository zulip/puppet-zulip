puppet-zulip
=============

Description
-----------

A Puppet report handler for sending notifications to Zulip.  You'll
need a Zulip account.

Based on handlers by James Turnbull!

Requirements
------------

* `puppet`

Installation & Usage
--------------------

1.  Install puppet_zulip as a module in your Puppet master's module
    path.

2.  Get an API bot email & key from zulip [here][https://zulip.com/#settings]

3.  Edit variables in the file `zulip.yaml` and then copy the file to `/etc/puppet/` or for puppet enterpise '/etc/puppetlabs/puppet'.
    Update: 
    * `botemail`, `key` with values from #2.
    * `type`  = stream or private,
    * `to` (Stream name or email to send a private message)
    * `subject` (for stream subjects)   (only needed for stream.s)
    * `zulip_statuses` should be an array of statuses to send notifications for and defaults to `'failed'`. Specify `'all'` to receive notifications from all Puppet runs.
    * `github_user`: github.com user account. If specified, the report processor will create a Gist containing the log output from the run and link it in the IRC notification.
    * `github_password`: above github user's password.
    * `parsed_reports_dir`: path to a directory on the reportserver. If specified, a human-readable version of the report will be saved in this directory, and it's path will be mentioned in the IRC notification. Don't forget to create the directory on your reportserver, writeable to the user running the puppet-master, and setup a job to clean old reports.
    * `logs`: Boolean.  Send the human readable version of the report (only output, not summaries) in the message itself.
    * `report_url`: an URL, which if specified, will be appended to the IRC notification. Some special characters will be expanded to values found in the report. Example: `http://foreman.example.com/hosts/%h/reports/last`. Currently supported characters include:
      * `%c`: configuration version string
      * `%e`: puppet's run environment
      * `%h`: host name from the report
      * `%k`: kind of report
      * `%s`: report status
      * `%t`: report timestamp
      * `%v`: puppet version
    * `zulip_site`: an URL to your Zulip arbitrary server.

4. Or you can also use this by including the class in a manifest, with either parameters or hiera to set the settings. It will create the settings file in the correct place for you.

5.  Enable reports on your master `puppet.conf`

        [master]
        report = true
        reports = zulip

6.  Run the Puppet client and sync the report as a plugin

7.  To temporarially disable Zulip notifications add a file named 'zulip_disabled' in the same path as zulip.yaml.
    (Removing it will re-enable notifications)

        $ touch /etc/puppet/zulip_disabled

Author
------

Matthew Barr <mbarr@mbarr.net>

Based on code by James Turnbull <james@lovedthanlost.net>
(puppet-hipchat & puppet-twilio & puppet-irc )


License
-------

    Author:: Matthew Barr (<mbarr@mbarr.net>)
    Copyright:: Copyright (c) 2013 Matthew Barr
    License:: Apache License, Version 2.0

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
