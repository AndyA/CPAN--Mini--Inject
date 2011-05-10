use Test::More tests => 11;

use CPAN::Mini::Inject;
use File::Path;
use File::Copy;
use File::Basename;
use Compress::Zlib;

rmtree( ['t/local/MYCPAN/modulelist'], 0, 1 );
copy(
  't/local/CPAN/modules/02packages.details.txt.gz.original',
  't/local/CPAN/modules/02packages.details.txt.gz'
);
chmod oct(666), 't/local/CPAN/modules/02packages.details.txt.gz';
chmod oct(666), "t/local/CPAN/authors/01mailrc.txt.gz" if -f "t/local/CPAN/authors/01mailrc.txt.gz";
rmtree( ['t/local/CPAN/authors'], 0, 1 );
mkdir( 't/local/CPAN/authors' );
copy(
  't/local/01mailrc.txt.gz.original',
  't/local/CPAN/authors/01mailrc.txt.gz'
);
chmod oct(666), 't/local/CPAN/authors/01mailrc.txt.gz';
mkdir( 't/local/MYCPAN' );

my $mcpi;
my $module = "S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz";

$mcpi = CPAN::Mini::Inject->new;

## add two modules
$mcpi->loadcfg( 't/.mcpani/config' )->parsecfg->readlist->add(
  module   => 'CPAN::Mini::Inject',
  authorid => 'SSORICHE',
  version  => '0.01',
  file     => 't/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz'
 )->add(
  module   => 'CPAN::Mini::Inject',
  authorid => 'SSORICHE',
  version  => '0.02',
  file     => 't/local/mymodules/CPAN-Mini-Inject-0.01.tar.gz'
 )->writelist;

ok( $mcpi->inject,                        'Copy modules' );
ok( -e "t/local/CPAN/authors/id/$module", 'Module file exists' );
ok( -e 't/local/CPAN/authors/id/S/SS/SSORICHE/CHECKSUMS',
  'Checksum created' );

SKIP: {
  skip "Not a UNIX system", 3 if ( $^O =~ /^MSWin/ );
  is( ( stat( "t/local/CPAN/authors/id/$module" ) )[2] & 07777,
    0664, 'Module file mode set' );
  is(
    ( stat( dirname( "t/local/CPAN/authors/id/$module" ) ) )[2] & 07777,
    0775,
    'Author directory mode set'
  );
  is(
    ( stat( 't/local/CPAN/authors/id/S/SS/SSORICHE/CHECKSUMS' ) )[2]
     & 07777,
    0664,
    'Checksum file mode set'
  );
}

my @goodfile = <DATA>;
ok( my $gzread
   = gzopen( 't/local/CPAN/modules/02packages.details.txt.gz', 'rb' ) );

my @packages;
my $package;
while ( $gzread->gzreadline( $package ) ) {
  if ( $package =~ /^Written-By:/ ) {
    push( @packages, "Written-By:\n" );
    next;
  }
  if ( $package =~ /^Last-Updated:/ ) {
    push( @packages, "Last-Updated:\n" );
    next;
  }
  push( @packages, $package );
}
$gzread->gzclose;

is_deeply( \@goodfile, \@packages );

ok( my $gzauthread
   = gzopen( 't/local/CPAN/authors/01mailrc.txt.gz', 'rb' ) );

my $author;
my $author_was_injected = 0;
while ( $gzauthread->gzreadline( $author ) ) {
  if ( $author =~ /SSORICHE/ ) {
    $author_was_injected++;
  }
}
$gzauthread->gzclose;
ok( $author_was_injected,      'author injected into 01mailrc.txt.gz' );
ok( $author_was_injected == 1, 'author injected exactly 1 time' );

unlink( 't/local/CPAN/authors/id/S/SS/SSORICHE/CHECKSUMS' );
unlink( "t/local/CPAN/authors/id/$module" );
unlink( 't/local/MYCPAN/modulelist' );
unlink( 't/local/CPAN/modules/02packages.details.txt.gz' );

rmtree( [ 't/local/CPAN/authors', 't/local/MYCPAN' ], 0, 1 );

__DATA__
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Package names found in directory $CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:
Line-Count:   6
Last-Updated:

Acme::Code::Police               2.1828  O/OV/OVID/Acme-Code-Police-2.1828.tar.gz
BFD                                0.31  R/RB/RBS/BFD-0.31.tar.gz
CPAN::Mini                         0.16  R/RJ/RJBS/CPAN-Mini-0.16.tar.gz
CPAN::Mini::Inject                 0.02  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz
CPAN::Nox                          1.02  A/AN/ANDK/CPAN-1.76.tar.gz
CPANPLUS                          0.049  A/AU/AUTRIJUS/CPANPLUS-0.049.tar.gz
