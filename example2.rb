#
# example2.rb
#

require './bgp-server.rb'

cap = Capability.new
cap1 = MpExtensionCapability.new(:ipv4, :unicast)
cap2 = MpExtensionCapability.new(:ipv6, :unicast)
cap3 = FourOctetAsCapability.new(7675)
cap.add(cap1)
cap.add(cap2)
cap.add(cap3)

opt = OptionalParameter.new
opt.add(cap)

open = Open.new(7675, '172.16.167.1', opt)
openmsg = BgpMsg.new(open)

origin = Origin.new
pathseg1 = AsPathSegment.new([100, 101, 102, 65536, 65537], true)
aspath = AsPath.new
aspath.add(pathseg1)
localpref = LocalPreference.new(200)

mp_nlri = MpReachNlri.new("2001:0db8:0001::1", "2001:0db8:0001::/48")

path_attr = PathAttribute.new
path_attr.add(origin)
path_attr.add(aspath)
path_attr.add(localpref)
path_attr.add(mp_nlri)

nlri = Empty.new
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
