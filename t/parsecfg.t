use Test::More tests => 11;

use CPAN::Mini::Inject;

my $mcpi = CPAN::Mini::Inject->new;
$mcpi->loadcfg( 't/.mcpani/config' );
$mcpi->parsecfg;
is( $mcpi->{config}{local},      't/local/CPAN' );
is( $mcpi->{config}{remote},     'http://localhost:11027' );
is( $mcpi->{config}{repository}, 't/local/MYCPAN' );

$mcpi = CPAN::Mini::Inject->new;
$mcpi->parsecfg( 't/.mcpani/config' );
is( $mcpi->{config}{local},      't/local/CPAN' );
is( $mcpi->{config}{remote},     'http://localhost:11027' );
is( $mcpi->{config}{repository}, 't/local/MYCPAN' );


$mcpi = CPAN::Mini::Inject->new;
$mcpi->parsecfg( 't/.mcpani/config_with_whitespaces' );
is( $mcpi->{config}{local},      't/local/CPAN' );
is( $mcpi->{config}{remote},     'http://localhost:11027' );
is( $mcpi->{config}{repository}, 't/local/MYCPAN' );
is( $mcpi->{config}{dirmode},    '0775' );
is( $mcpi->{config}{passive},    'yes' );
