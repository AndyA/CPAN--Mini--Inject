use Test::More tests => 1;

use CPAN::Mini::Inject;

my $mcpi = CPAN::Mini::Inject->new;
isa_ok( $mcpi, 'CPAN::Mini::Inject' );
