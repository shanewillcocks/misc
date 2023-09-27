#!/usr/bin/perl
#----------------------------------------------
# Bind to a port to test remote connections
# Use: socket_test.pl -p <PORT>
#----------------------------------------------
use IO::Socket::INET;
use Sys::Hostname;
use Getopt::Std;

getopts( 'p:', \%port );
if ( keys( %port ) == 1 ) {
        my $ipaddr = inet_ntoa( ( gethostbyname( hostname ) )[4] );
        my $proto = ( getprotobyname( 'tcp' ) )[2];
        my ( $socket, $clientsocket );
        my ( $clientaddr, $clientip );

        $socket = new IO::Socket::INET (
                LocalHost => $ipaddr,
                LocalPort => $port{p},
                Proto => $proto,
                Listen => 5,
                Reuse => 1
                ) or die "Could not create socket: $!";
        print "Listening for incoming connections on $ipaddr:$port{p}\n";
        while ( true ) {
                $clientsocket = $socket->accept();
                $clientip = $clientsocket->peerhost();
                $clientport = $clientsocket->peerport();
                print "Connection accepted from: $clientip on $clientport\n";
                $clientsocket->send( "Server: connection from $clientip OK\n" );
                $clientsocket->send( "Server: closing connection in 5 seconds\n" );
                print "Closing connection in 5 seconds\n";
                sleep 5;
                $clientsocket->send( "Server: Connection closed\n" );
                $clientsocket->close();
                print "Closed connection from $clientip\n";
        }
        $socket->close();
} else {
        print "Usage: ".$0." -p <port>\n";
        exit;
}
