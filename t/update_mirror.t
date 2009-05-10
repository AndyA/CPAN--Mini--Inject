use Test::More;
use File::Spec::Functions;
use strict;
use warnings;

use lib catdir( 't', 'lib' );

BEGIN {
  eval "use CPANServer";

  plan skip_all => "HTTP::Server::Simple required to test update_mirror"
   if $@;
  plan tests => 8;
}

use CPAN::Mini::Inject;
use File::Path;

rmtree( [ catdir( 't', 'mirror' ) ], 0, 1 );

my $server = CPANServer->new( 11027 );
my $pid    = $server->background;
ok( $pid, 'HTTP Server started' );

$SIG{__DIE__} = sub { kill( 9, $pid ) };

my $mcpi = CPAN::Mini::Inject->new;
$mcpi->parsecfg( 't/.mcpani/config' );

mkdir( catdir( 't', 'mirror' ) );

$mcpi->update_mirror(
  remote => 'http://localhost:11027',
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

rmtree( [ catdir( 't', 'mirror' ) ], 0, 1 );
