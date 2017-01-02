bgp-server.rb
=============

by Motonori Shindo <motonori@shin.do> (2012 - 2017)

This is a very simple BGP4 implementation written by Ruby. The purpose of 
this code is to allow users to manipulate BGP4 message and send it to the 
peer with a great deal of flexibility. There is no intent to support 
everything that BGP4 is capable of. Because of this design goal, the 
abstraction level is set to somewhat low on purpose.

Please note that this is a "server for passive client" implementation, 
meaning it doesn't initiate a BGP4 session from itself (hence "server") 
and doesn't receive any UPDATE message from the peer (hence "for passive 
client"). 

Please enjoy!

License
-------

GNU General Public License, verion 2 (GPL-2.0)
