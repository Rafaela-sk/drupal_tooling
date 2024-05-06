#!/usr/bin/perl -w

# tries to connect to the given IP and port (tcp)

use strict;
use IO::Socket;

my $desthost = shift or die "Usage: $0 host port\n";
my $destport = shift or die "Usage: $0 host port\n";

gethostbyname($desthost) || die "Invalid host given\n";

my $handle = IO::Socket::INET->new(
        PeerAddr => $desthost,
        PeerPort => $destport,
        Proto    => 'tcp')
    or die "can't connect to $desthost:$destport: $!\n";
close $handle;
print "Success!\n"
