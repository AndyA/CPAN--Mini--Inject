use Test::More tests => 2;

use CPAN::Mini::Inject;

my $mcpi;
my $module
 = "CPAN::Mini::Inject                 0.01  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz";

unlink( 't/local/MYCPAN/modulelist' );

genmodlist();

$mcpi = CPAN::Mini::Inject->new;
$mcpi->loadcfg( 't/.mcpani/config' )->parsecfg->readlist;

push( @{ $mcpi->{modulelist} }, $module );
is( @{ $mcpi->{modulelist} }, 4, 'Updated memory modulelist' );
ok( $mcpi->writelist, 'Write modulelist' );

unlink( 't/local/MYCPAN/modulelist' );

sub genmodlist {
  open( MODLIST, '>t/local/MYCPAN/modulelist' )
   or die "Can not create t/local/MYCPAN/modulelist: $!";
  print MODLIST << "EOF"
CPAN::Checksums                   1.016  A/AN/ANDK/CPAN-Checksums-1.016.tar.gz
CPAN::Mini                         0.18  R/RJ/RJBS/CPAN-Mini-0.18.tar.gz
CPANPLUS                         0.0499  A/AU/AUTRIJUS/CPANPLUS-0.0499.tar.gz
EOF
   ;
  close( MODLIST );
}
