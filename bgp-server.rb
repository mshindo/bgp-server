require 'socket'
require 'ipaddr'

# TODO:
#   - ASPath, AS4Path extended length support
#   - Thread support
#   - Peer Capability Detection
#   - More annotations
#   - Document

class BgpMsg
  
  def initialize(msg)
    @msg = msg
  end
  
  def length
    pack.length
  end
  
  def pack
    ([0xff] * 16 + [@msg.length + 19, @msg.type]).pack('C16nC') + @msg.pack
  end
  
end


class Open
  
  def initialize(my_as, bgp_id, opt_params = nil, hold_time = 180)
    @my_as = my_as
    @bgp_id = IPAddr.new(bgp_id).to_i
    @hold_time = hold_time
    @opt_params = opt_params || Empty.new
  end
  
  def type
    1   # OPEN
  end
  
  def length
    1 + 2 + 2 + 4 + 1 + @opt_params.length
  end
  
  def pack
    [4, @my_as, @hold_time, @bgp_id, @opt_params.length].pack('CnnNC') +
    @opt_params.pack
  end
  
end


class Update
  
  def initialize(path_attr, nlri)
    @path_attr = path_attr
    @nlri = nlri
  end
  
  def type
    2   # UPDATE
  end
  
  def length
    2 + 0 + 2 + @path_attr.length + @nlri.length
  end
  
  def pack
    [0, @path_attr.length].pack('nn') + @path_attr.pack + @nlri.pack
  end
  
end


class Notification
  
  def initialize(err, suberr, data)
    @err = err
    @suberr = suberr
    @data = data
  end
  
  def type
    3   # NOTIFICATION
  end
  
  def length
    1 + 1 + @data.length
  end
  
  def pack
    [@err, @suberr].pack('CC') + @data
  end
  
end


class KeepAlive
  
  def type
    4   # KEEPALIVE
  end
  
  def length
    0
  end

  def pack
    ''
  end
  
end


module PackableList
  
  def initialize
    @list = []
  end
  
  def add(obj)
    @list << obj
  end

  def list_length
    if @list.empty?
      0
    else
      @list.map {|p| p.length}.inject {|r, i| r + i}
    end
  end
  
  def extended
    list_length > 255 ? true : false
  end
  
  def list_pack
    if @list.empty?
      ''
    else
      @list.map {|p| p.pack}.inject {|r, i| r + i}
    end
  end
  
end


class Empty
  
  def length
    0
  end
  
  def pack
    ''
  end
  
end


class OptionalParameter
  
  include PackableList

  def length
    list_length
  end
  
  def pack
    list_pack
  end
  
end


class Capability
  
  include PackableList
  
  def length
    1 + 1 + list_length
  end
  
  def pack
    [2, list_length].pack('CC') + list_pack
  end
  
end


class MpExtensionCapability
  
  def initialize(afi, safi)
    afi_val = {:ipv4 => 1, :ipv6 => 2}
    safi_val = {:unicast => 1, 
                :multicast => 2,
                :mpls_label => 4,
                :mpls_labeled_vpn => 128}
    @afi = afi_val[afi]
    @safi = safi_val[safi]
  end
  
  def length
    1 + 1 + 2 + 1 + 1
  end
  
  def pack
    [1, 4, @afi, 0, @safi].pack('CCnCC')
  end
  
end


class RouteRefreshCapability
  
  def length
    1 + 1
  end
  
  def pack
    [2, 0].pack('CC')
  end
  
end


class RouteRefreshOldCapability
  
  def length
    1 + 1
  end
  
  def pack
    [128, 0].pack('CC')
  end
  
end


class FourOctetAsCapability
  
  def initialize(my_as)
    @my_as = my_as
  end
  
  def length
    6
  end
  
  def pack
    [65, 4, @my_as].pack('CCN')
  end
  
end


#
# This is just a mock. In reality, it is a much more complicated object.
#
class GracefulRestartCapability
  
  def length
    4
  end
  
  def pack
    [64, 2, 0x00, 0x78].pack('CCCC')
  end
end

#
# Path Attributes
#

class PathAttribute
  
  include PackableList

  def length
    list_length
  end
  
  def pack
    list_pack
  end

end


class Origin
  
  def initialize(origin = :igp)
    origin_val = {:igp => 0, :egp => 1, :incomplete => 2}
    @origin = origin_val[origin]
  end
  
  def length
    4
  end

  def pack
    [0x40, 1, 1, @origin].pack('CCCC')
  end
  
end


class AsPathSegment
  
  def initialize(as_pathseg, as4byte = false, type = :as_seq)
    @as_pathseg = as_pathseg
    @as4byte = as4byte
    type_val = {:as_set => 1, :as_seq => 2}
    @type = type_val[type]
  end
  
  def mappable?
    @as_pathseg.all? {|asn| asn < 65536}
  end
  
  def length
    1 + 1 + @as_pathseg.length * (@as4byte ? 4 : 2)
  end
  
  def pack
    ([@type, @as_pathseg.length] + @as_pathseg).pack(@as4byte ? 'CCN*' : 'CCn*')
  end
  
end


class AsPath
  
  include PackableList
  
  def length
    1 + 1 + (extended ? 2 : 1) + list_length
  end
  
  def pack
    if extended
      [0x50, 2, list_length].pack('CCn') + list_pack
    else
      [0x40, 2, list_length].pack('CCC') + list_pack
    end
  end
  
end


class NextHop

  def initialize(ipaddr)
    @ipaddr = ipaddr
  end
  
  def length
    1 + 1 + 1 + 4
  end

  def pack
    [0x40, 3, 4, IPAddr.new(@ipaddr).to_i].pack('CCCN')
  end

end


class LocalPreference
  
  def initialize(preference = 100)
    @preference = preference
  end
  
  def length
    1 + 1 + 1 + 4
  end

  def pack
    [0x40, 5, 4, @preference].pack('CCCN')
  end

end


class Community

  def initialize(comm = [:no_export])
    comm_val = {:no_export => 0xffffff01, 
                :no_advertise => 0xffffff02,
                :no_export_subconfed => 0xffffff03}
    @comm = comm.map {|c| comm_val[c] || c}
  end
  
  def length
    pack.length
  end

  def pack
    if @comm.length < 64
      ([0xc0, 8, 4 * @comm.length] + @comm).pack('CCCN*')
    else
      # extended length
      ([0xd0, 8, 4 * @comm.length] + @comm).pack('CCnN*')
    end
  end

end



class MpReachNlri
  
  def initialize(nexthop, nlri, afi = :ipv6, safi = :unicast)
    @nexthop = IPAddr.new(nexthop)
    @nlri = Nlri.new(nlri)
    # Duplicate with MpExtensionCapability. Needs refactoring!
    afi_val = {:ipv4 => 1, :ipv6 => 2}
    safi_val = {:unicast => 1, 
                :multicast => 2,
                :mpls_label => 4,
                :mpls_labeled_vpn => 128}
    @afi = afi_val[afi]
    @safi = safi_val[safi]
  end
  
  def length
    pack.length # ???
  end
  
  # this is a hack, simply assuming IPv6. needs more flexibility.
  def pack
    # assuming extended length encoding. needs fix.
    [0x90, 14, 21+@nlri.length, @afi, @safi].pack('CCnnC') +
    [16].pack('C') + @nexthop.hton +
    [0].pack('C') + @nlri.pack
  end
  
end


class Nlri

  def initialize(prefixes)
    @prefixes = prefixes
  end
  
  def length
    pack.length     # is this really OK?
  end
  
  def pack
    @prefixes.map {|p| to_nlri(p)}.join
  end

  private
  def to_nlri(str)
    ip = IPAddr.new(str)
    masklen = str.split('/').last.to_i
    [masklen].pack('C') + ip.hton.slice(0, (masklen + 7)/8)
  end
      
end


class Bgp
  def initialize
    bgp = TCPServer.open(179)
    @sock = bgp.accept
    bgp.close
  end
  
  def start
    @sock.read(16)        # marker
    msg = @sock.read(2 + 1).unpack('nC')
    len = msg[0]
    type = msg[1]
    # puts "message type #{type} received"
  end

  def send(msg)
    @sock.write(msg.pack)
    # puts "message sent"
  end
  
end


