#
# example1.rb
#

require 'bgp-server'

open = Open.new(7675, '172.16.167.1')
openmsg = BgpMsg.new(open)

origin = Origin.new
pathseg1 = AsPathSegment.new([100, 101, 102])
aspath = AsPath.new
aspath.add(pathseg1)
nexthop = NextHop.new('11.0.0.2')
localpref = LocalPreference.new

path_attr = PathAttribute.new
path_attr.add(origin)
path_attr.add(aspath)
path_attr.add(nexthop)
path_attr.add(localpref)

nlri = Nlri.new(['10.0.0.0/8', '20.0.0.0/16'])
update = Update.new(path_attr, nlri)
updatemsg = BgpMsg.new(update)

keepalive = KeepAlive.new
keepalivemsg = BgpMsg.new(keepalive)

bgp = Bgp.new
bgp.start
bgp.send openmsg
puts "OPEN sent"
bgp.send keepalivemsg
puts "KEEPALIVE sent"

bgp.send updatemsg
puts "UPDATE sent"

loop do
  sleep 30
  bgp.send keepalivemsg
  puts "KEEPALIVE sent"
end
