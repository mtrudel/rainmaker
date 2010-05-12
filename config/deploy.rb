# 
# Rainmaker -- the pragmatic UEC manager
#
# Tired of trying to get euca2ools or ami-tools working on every developer 
# machine on your team? Well, tire no longer. This quick set of capistrano 
# recipes lets you control a UEC cluster by interacting with the euca-* tools
# already on the cluster controller. It may not be architecturally elegant
# (or maybe it is, depending on your persuation), but it works. 
#
# Assumptions: 
#   - euca-tools are installed on the machine fulfilling the 'cc' role, and 
#     can be run by 'user' without having to specify any extra command line 
#     options (ie: all the environment variables are properly set on the 
#     remote end)
#   - config/rainmaker.yml contains all the public keys you want to bootstrap
#     your new VM with
#   - You have the ruports gem / rip installed locally
#
#  Copyright 2010 Mat Trudel at Well.ca (mat@well.ca). BSD license applies
#
set :application, "rainmaker"

role :cc, "X.Y.X.Y" # This is a remote machine with euca2ools installed. Normally your cluster controller.
set :user, "user"  # Set this to a remote user with permission to use euca-* tools

set :emi, ENV['EMI'] || "emi-XXXXXXXX"  # Set this to the default emi you want to instantiate
set :machine_type, ENV['MACHINE_TYPE'] || "m1.small" # Set this to the default machine type you want to instantiate

logger.level = 0

namespace :uec do
  desc "Starts a new UEC instance"
  task :new_instance do
    config_file = "rainmaker-#{rand(1000000)}"
    upload(File.join(File.dirname(__FILE__), "rainmaker.yml"), config_file)
    output = capture "euca-run-instances -f #{config_file} -t #{machine_type} #{emi}"
    run "rm #{config_file}"
    instance = output.match(/INSTANCE\W*([\w\-]*)/)[1]
    print "Got instance #{instance}. Waiting a few seconds to get its IP address..."
    print "." until sleep(5) && capture('euca-describe-instances').match(/^INSTANCE\W*#{instance}\W*[\w\-]*\W*[\d\.]*\W*[\d\.]*\W*([\w\-]*).*$/)[1] == 'running'
    puts "\nYour new instance's IP address is #{capture('euca-describe-instances').match(/^INSTANCE\W*#{instance}\W*[\w\-]*\W*([\d\.]*).*$/)[1]}"
  end
  
  desc "Lists all UEC instances"
  task :list_instances do
    require 'ruport'
    output = capture "euca-describe-instances"
    data = Ruport::Data::Table.new(:column_names => %w(Instance\ ID Image IP State Type))
    output.scan(/^INSTANCE\W*([\w\-]*)\W*([\w\-]*)\W*([\d\.]*)\W*[\d\.]*\W*([\w\-]*)\W*[\d]*\W*([\w\.]*).*$/).each { |m| data << m }
    puts data.to_txt
  end
  
  desc "Terminates a current UEC instance"
  task :terminate_instance do
    uec.list_instances
    instance = Capistrano::CLI.ui.ask("Instance ID(s): ")
    output = capture "euca-terminate-instances #{instance}"
  end
end
