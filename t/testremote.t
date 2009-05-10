use Test::More;

use CPAN::Mini::Inject;
use lib 't/lib';

BEGIN {
  eval "use CPANServer";

  plan skip_all => "HTTP::Server::Simple required to test update_mirror" if $@;
  plan tests => 3;
}

my $server=CPANServer->new;
my $pid=$server->background;
ok($pid,'HTTP Server started');

$SIG{__DIE__} = sub { kill(9,$pid) };

my $mcpi=CPAN::Mini::Inject->new;
$mcpi->loadcfg('t/.mcpani/config')
     ->parsecfg;

$mcpi->testremote;
is($mcpi->{site},'http://localhost:8080/','Correct remote URL');

$mcpi->loadcfg('t/.mcpani/config_badremote')
     ->parsecfg;

$mcpi->testremote;
is($mcpi->{site},'http://localhost:8080/','Selects correct remote URL');

kill(9,$pid);

unlink('t/testconfig');
