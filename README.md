Rainmaker -- the pragmatic UEC manager
======================================

Tired of trying to get euca2ools or ami-tools working on every developer 
machine on your team? Well, tire no longer. This quick set of capistrano 
recipes lets you control a UEC cluster by interacting with the euca-* tools
already on the cluster controller. It may not be architecturally elegant
(or maybe it is, depending on your persuasion), but it works. 

Assumptions
-----------
*  euca-tools are installed on the machine fulfilling the 'cc' role, and 
   can be run by 'user' without having to specify any extra command line 
   options (ie: all the environment variables are properly set on the 
   remote end)
*  config/rainmaker.yml contains all the public keys you want to bootstrap
   your new VM with
*  You have the ruports gem / rip installed locally