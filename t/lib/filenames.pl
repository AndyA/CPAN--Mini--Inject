$WriteRepo = catfile( qw(t local WRITEREPO) );

%MYCPAN => ( dir => catfile( qw(t read MYCPAN) ), );

my @files = qw(modulelist test-0.01.tar.gz);
$MYCPAN{@files} = map { catfile( $MYCPAN{dir}, $_ ) } @files;

return 1 if ( -r '/usr/local/etc/mcpani' );
return 1 if ( -r '/etc/mcpani' );

# parsecfg()
dies_ok { $mcpi->parsecfg( catfile( qw(t .mcpani config_bad) ) ); }
'Missing config option';

mkdir catfile( qw(t local MYCPAN) );
$mcpi->parsecfg( catfile( qw(t .mcpani config_noread) ) );
dies_ok { $mcpi->readlist } 'unreadable file';

$mcpi->parsecfg( catfile( qw(t .mcpani config) ) );

$mcpi->parsecfg( catfile( qw(t .mcpani config_norepo) ) );

dies_ok {
  $mcpi->add(
    module   => 'CPAN::Mini::Inject',
    authorid => 'SSORICHE',
    version  => '0.01',
    file     => 'test-0.01.tar.gz'
  );
}
'Missing config repository';

$mcpi->parsecfg( catfile( qw(t .mcpani config_read) ) );

$mcpi->parsecfg( catfile( qw(t .mcpani config_nowrite) ) );
dies_ok { $mcpi->writelist } 'fail write file';

mkdir catfile( qw(t local WRITEREPO) );
open WRITEFILE, '>', catfile( qw(t local WRITEREPO modulelist) );
close WRITEFILE;
chmod 0222, catfile( qw(t local WRITEREPO modulelist) );

chmod 0555, catfile( qw(t read MYCPAN) );
chmod 0444, catfile( qw(t read MYCPAN modulelist) );
chmod 0444, catfile( qw(t read MYCPAN test-0.01.tar.gz) );

