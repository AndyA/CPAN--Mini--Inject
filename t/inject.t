use Test::More tests => 12;

use Test::InDistDir;
use CPAN::Mini::Inject;
use File::Path;
use File::Copy;
use File::Basename;
use Compress::Zlib;

my $root = "t/local";
my $modules = "$root/CPAN/modules";
my $authors = "$root/CPAN/authors";
my $mycpan = "$root/MYCPAN";
my $mymodules = "$root/mymodules";

rmtree( ["$mycpan/modulelist"], 0, 1 );
copy(
  "$modules/02packages.details.txt.gz.original",
  "$modules/02packages.details.txt.gz"
);
chmod oct(666), "$modules/02packages.details.txt.gz";
chmod oct(666), "$authors/01mailrc.txt.gz" if -f "$authors/01mailrc.txt.gz";
rmtree( [$authors], 0, 1 );
mkdir( $authors );
copy(
  "$root/01mailrc.txt.gz.original",
  "$authors/01mailrc.txt.gz"
);
chmod oct(666), "$authors/01mailrc.txt.gz";
mkdir( $mycpan );

my $mcpi;
my $module = "S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz";

$mcpi = CPAN::Mini::Inject->new;

## add three modules (one that was already there, to make sure it isn't
## duplicated in the output)
$mcpi->loadcfg( 't/.mcpani/config' )->parsecfg->readlist->add(
  module   => 'CPAN::Mini::Inject',
  authorid => 'SSORICHE',
  version  => '0.01',
  file     => "$mymodules/CPAN-Mini-Inject-0.01.tar.gz"
 )->add(
  module   => 'CPAN::Mini::Inject',
  authorid => 'SSORICHE',
  version  => '0.02',
  file     => "$mymodules/CPAN-Mini-Inject-0.01.tar.gz"
 )->add(
  module   => 'CPAN::Mini',
  authorid => 'RJBS',
  version  => '0.17',
  file     => "$mymodules/CPAN-Mini-0.17.tar.gz",
 )->writelist;

ok( $mcpi->inject,                        'Copy modules' );
ok( -e "$authors/id/$module", 'Module file exists' );
my $checksum_file = "$authors/id/S/SS/SSORICHE/CHECKSUMS";
ok( -e "$checksum_file", 'Checksum created' );

open my $chk, '<', $checksum_file;
my $checksum_text = join "", <$chk>;
close $chk;
unlike $checksum_text, qr{$authors/id}, "root path isn't leaked to checksums";

SKIP: {
  skip "Not a UNIX system", 3 if ( $^O =~ /^MSWin|^cygwin/ );
  is( ( stat( "$authors/id/$module" ) )[2] & 07777,
    0664, 'Module file mode set' );
  is(
    ( stat( dirname( "$authors/id/$module" ) ) )[2] & 07777,
    0775, 'Author directory mode set'
  );
  is(
    ( stat( "$checksum_file" ) )[2] & 07777,
    0664, 'Checksum file mode set'
  );
}

my @goodfile = <DATA>;
ok( my $gzread
   = gzopen( "$modules/02packages.details.txt.gz", 'rb' ) );

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
   = gzopen( "$authors/01mailrc.txt.gz", 'rb' ) );

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

unlink( "$checksum_file" );
unlink( "$authors/id/$module" );
unlink( "$mycpan/modulelist" );
unlink( "$modules/02packages.details.txt.gz" );

rmtree( [ $authors, $mycpan ], 0, 1 );

__DATA__
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Package names found in directory $CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:
Line-Count:   7
Last-Updated:

abbreviation                       0.02  M/MI/MIYAGAWA/abbreviation-0.02.tar.gz
Acme::Code::Police               2.1828  O/OV/OVID/Acme-Code-Police-2.1828.tar.gz
BFD                                0.31  R/RB/RBS/BFD-0.31.tar.gz
CPAN::Mini                         0.17  R/RJ/RJBS/CPAN-Mini-0.17.tar.gz
CPAN::Mini::Inject                 0.02  S/SS/SSORICHE/CPAN-Mini-Inject-0.01.tar.gz
CPAN::Nox                          1.02  A/AN/ANDK/CPAN-1.76.tar.gz
CPANPLUS                          0.049  A/AU/AUTRIJUS/CPANPLUS-0.049.tar.gz
