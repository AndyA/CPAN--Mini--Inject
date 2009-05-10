use Test::More tests => 1;

BEGIN {
  use_ok( 'CPAN::Mini::Inject' );
}

diag( "Testing CPAN::Mini::Inject $CPAN::Mini::Inject::VERSION" );

# Setup for other tests

mkdir( 't/local/WRITEREPO' );
open( WRITEFILE, '>', 't/local/WRITEREPO/modulelist' );
close( WRITEFILE );
chmod( 0222, 't/local/WRITEREPO/modulelist' );

chmod( 0555, 't/read/MYCPAN' );
chmod( 0444, 't/read/MYCPAN/modulelist' );
chmod( 0444, 't/read/MYCPAN/test-0.01.tar.gz' );

