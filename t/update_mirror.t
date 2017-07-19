use Test::More;
use File::Spec::Functions;
use strict;
use warnings;

use lib 't/lib';

BEGIN {
  plan skip_all => "HTTP::Server::Simple required to test update_mirror"
   if not eval "use CPANServer; 1";
  plan skip_all => "Net::EmptyPort required to test update_mirror"
   if not eval "use Net::EmptyPort; 1";
  plan tests => 8;
}

use CPAN::Mini::Inject;
use File::Path;

rmtree( [ catdir( 't', 'mirror' ) ], 0, 1 );

my $port = Net::EmptyPort::empty_port;
my $server = CPANServer->new( $port );
my $pid    = $server->background;
ok( $pid, 'HTTP Server started' );
sleep 1;

$SIG{__DIE__} = sub { kill( 9, $pid ) };

my $mcpi = CPAN::Mini::Inject->new;
$mcpi->parsecfg( 't/.mcpani/config' );
$mcpi->{config}{remote} =~ s/:\d{5}\b/:$port/;

mkdir( catdir( 't', 'mirror' ) );

$mcpi->update_mirror(
  remote => "http://localhost:$port",
  local  => catdir( 't', 'mirror' )
);

kill( 9, $pid );

ok( -e catfile( qw(t mirror authors 01mailrc.txt.gz) ),
  'Mirrored 01mailrc.txt.gz' );
ok( -e catfile( qw(t mirror modules 02packages.details.txt.gz) ),
  'Mirrored 02packages.details.txt.gz' );
ok( -e catfile( qw(t mirror modules 03modlist.data.gz) ),
  'Mirrored 03modlist.data.gz' );

ok( -e catfile( qw(t mirror authors id R RJ RJBS CHECKSUMS) ),
  'RJBS CHECKSUMS' );
ok(
  -e catfile(
    qw(t mirror authors id R RJ RJBS CPAN-Mini-2.1828.tar.gz) ),
  'CPAN::Mini'
);
ok( -e catfile( qw(t mirror authors id S SS SSORICHE CHECKSUMS) ),
  'SSORICHE CHECKSUMS' );
ok(
  -e catfile(
    qw(t mirror authors id S SS SSORICHE CPAN-Mini-Inject-1.01.tar.gz)
  ),
  'CPAN::Mini::Inject'
);
sleep 1; # allow locks to expire
rmtree( [ catdir( 't', 'mirror' ) ], 0, 1 );
