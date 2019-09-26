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

# prep env

puts "#{skcmd} #{skgargs} #{skcargs} cluster init --control-plane #{k8svip} #{clustername}"

# take first master and bootstrap

bsnode = tarmac['masters'].first
# remove first master we used from list of masters
tarmac['masters'].delete(bsnode)
puts "#{skcmd} #{skgargs} node bootstrap --user #{skuser} --target sudo #{bsnode} #{bsnode}"

# add remaining masters (if any)
tarmac['masters'].each do |master|
#  skuba node join --role master --user sles --sudo --target
  puts "#{skcmd} #{skgargs} node #{sknargs} join --role master --user #{skuser} --sudo --target #{master} #{master}"
end

# add workers second (if any)
tarmac['workers'].each do |worker|
  puts "#{skcmd} #{skgargs} node #{sknargs} join --role worker --user #{skuser} --sudo --target #{worker} #{worker}"
end
