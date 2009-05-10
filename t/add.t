use Test::More tests => 5;

use CPAN::Mini::Inject;
use File::Path;

mkdir('t/local/MYCPAN');

my $mcpi;
$mcpi=CPAN::Mini::Inject->new;
$mcpi->loadcfg('t/.mcpani/config')
     ->parsecfg;

$mcpi->add( module => 'CPAN::Mini::Inject', authorid => 'SSORICHE', version => '0.01', file => 't/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz' );
is($mcpi->{authdir},'S/SS/SSORICHE','author directory');
ok(-r 't/local/MYCPAN/authors/id/S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz','Added module is readable');
my $module="CPAN::Mini::Inject                 0.01  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz";
ok(grep(/$module/,@{$mcpi->{modulelist}}),'Module added to list');

SKIP: {
  skip "Not a UNIX system", 2 if($^O =~ /^MSWin/);
  is((stat('t/local/MYCPAN/authors/id/S/SS/SSORICHE'))[2] & 07777,0775,'Added author directory mode is 0775');
  is((stat('t/local/MYCPAN/authors/id/S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz'))[2] & 07777,0664,'Added module mode is 0664');
}

# XXX do the same test as above again, but this time with a ->readlist after
# the ->parsecfg

rmtree('t/local/MYCPAN',0,1);
