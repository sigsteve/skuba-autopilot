#!/usr/bin/env ruby

require 'yaml'

tarmac = YAML.load(File.read('tarmac.yaml'))

clustername = tarmac['clustername']
skcmd       = tarmac['skubabin']
skuser      = tarmac['user'] || "nouser"
skgargs     = tarmac['skuba_extra_args']['global']
skcargs     = tarmac['skuba_extra_args']['cluster']
sknargs     = tarmac['skuba_extra_args']['node']
k8svip      = tarmac['apivip']
skdomain    = tarmac['domain']

# prep env

# puts "#{skcmd} #{skgargs} #{skcargs} cluster init --control-plane #{k8svip} #{clustername}"
# Will error if cluster is already initialized
system("#{skcmd} #{skgargs} #{skcargs} cluster init --control-plane #{k8svip} #{clustername}")

# change into cluster directory 
Dir.chdir("#{clustername}")

# skuba cluster status to an array for comparison
skcstatus = `#{skcmd} cluster status | awk 'FNR==1 {next} {print $1}'`.split("\n")

# take first master and bootstrap
bsnode = tarmac['masters'].first
# remove first master we used from list of masters
tarmac['masters'].delete(bsnode)
# bootstrap the first master node
# first check if its already been bootstrapped
if skcstatus.include?(bsnode) then
  puts "The first master node is already bootstrapped." 
else
  # bootstrap the first master node
  system("#{skcmd} #{skgargs} node bootstrap --user #{skuser} --target sudo #{bsnode}.#{skdomain} #{bsnode}")
end

# check for master nodes which have already been added to the cluster and remove them from the list
masters = tarmac['masters'].sort - skcstatus.sort - tarmac['workers'].sort 
# puts "#{masters}"

# add remaining masters (if any)
masters.each do |master|
# skuba node join --role master --user sles --sudo --target
# puts "#{skcmd} #{skgargs} node #{sknargs} join --role master --user #{skuser} --sudo --target #{master}.#{skdomain} #{master}"
  system("#{skcmd} #{skgargs} node #{sknargs} join --role master --user #{skuser} --sudo --target #{master}.#{skdomain} #{master}")
end

# check for worker nodes which have already been added to the cluster and remove them from the list
workers = tarmac['workers'].sort - skcstatus.sort - tarmac['masters'].sort 
#puts "#{workers}"

# add workers second (if any)
workers.each do |worker|
# puts "#{skcmd} #{skgargs} node #{sknargs} join --role worker --user #{skuser} --sudo --target #{worker}.#{skdomain} #{worker}"
  system("#{skcmd} #{skgargs} node #{sknargs} join --role worker --user #{skuser} --sudo --target #{worker}.#{skdomain} #{worker}")
end

# Print Cluster Status
system("#{skcmd} cluster status")
