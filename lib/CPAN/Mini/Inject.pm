package CPAN::Mini::Inject;

use strict;
use warnings;

use CPAN::Checksums qw( updatedir );
use CPAN::Mini;
use CPAN::Mini::Inject::Config;
use Carp;
use Compress::Zlib;
use Env;
use File::Basename;
use File::Copy;
use File::Path qw( make_path );
use File::Spec;
use LWP::Simple;

=head1 NAME

CPAN::Mini::Inject - Inject modules into a CPAN::Mini mirror.

=head1 VERSION

Version 0.30

=cut

our $VERSION = '0.30';
our @ISA     = qw( CPAN::Mini );

=head1 Synopsis

If you're not going to customize the way CPAN::Mini::Inject works you
probably want to look at the mcpani command instead.

    use CPAN::Mini::Inject;

    $mcpi=CPAN::Mini::Inject->new;
    $mcpi->parsecfg('t/.mcpani/config');

    $mcpi->add( module   => 'CPAN::Mini::Inject',
                authorid => 'SSORICHE',
                version  => ' 0.01',
                file     => 'mymodules/CPAN-Mini-Inject-0.01.tar.gz' );

    # or...

    $mcpi->add( modules  => { Foo::Bar => '0.01', Foo::Baz => '0.03' },
                authorid => 'SSORICHE',
                file     => 'mymodules/Distro-With-Many-Modules-1.2.tar.gz' );

    $mcpi->writelist;
    $mcpi->update_mirror;
    $mcpi->inject;

=head1 DESCRIPTION

CPAN::Mini::Inject uses CPAN::Mini to build or update a local CPAN mirror
then adds modules from your repository to it, allowing the inclusion
of private modules in a minimal CPAN mirror.

=head1 METHODS

Each method in CPAN::Mini::Inject returns a CPAN::Mini::Inject object which
allows method chaining. For example:

    my $mcpi=CPAN::Mini::Inject->new;
    $mcpi->parsecfg
         ->update_mirror
         ->inject;

A C<CPAN::Mini::Inject> ISA L<CPAN::Mini>. Refer to the
L<documentation|CPAN::Mini> for that module for details of the interface
C<CPAN::Mini::Inject> inherits from it.

=head2 C<new>

Create a new CPAN::Mini::Inject object.

=cut

sub new {
  return bless
   { config_class => 'CPAN::Mini::Inject::Config' },
   $_[0];
}

=head2 C<< config_class( [CLASS] ) >>

Returns the name of the class handling the configuration.

With an argument, it sets the name of the class to handle
the config. To use that, you'll have to call it before you
load the configuration.

=cut

sub config_class {
  my $self = shift;

  if ( @_ ) { $self->{config_class} = shift }

  $self->{config_class};
}

=head2 C<< config >>

Returns the configuration object. This object should be from
the class returned by C<config_class> unless you've done something
wierd.

=cut

sub config {
  my $self = shift;

  if ( @_ ) { $self->{config} = shift }

  $self->{config};
}

=head2 C<< loadcfg( [FILENAME] ) >>


This is a bridge to CPAN::Mini::Inject::Config's loadconfig. It sets the
filename for the configuration, or uses one of the defaults.

=cut

sub loadcfg {
  my $self = shift;

  unless ( $self->{config} ) {
    $self->{config} = $self->config_class->new;
  }

  $self->{cfgfile} = $self->{config}->load_config( @_ );

  return $self;
}

=head2 C<< parsecfg() >>

This is a bridge to CPAN::Mini::Inject::Config's parseconfig.

=cut

sub parsecfg {
  my $self = shift;

  unless ( $self->{config} ) {
    $self->config( $self->config_class->new );
  }

  $self->config->parse_config( @_ );

  return $self;
}

=head2 C<< site( [SITE] ) >>

Returns the CPAN site that CPAN::Mini::Inject chose from the
list specified in the C<remote> directive.

=cut

sub site {
  no warnings;
  my $self = shift;

  if ( @_ ) { $self->{site} = shift }

  $self->{site} || '';
}

=head2 C<testremote>

Test each site listed in the remote parameter of the config file by performing
a get on each site in order for authors/01mailrc.txt.gz. The first site to
respond successfully is set as the instance variable site.

 print "$mcpi->{site}\n"; # ftp://ftp.cpan.org/pub/CPAN

C<testremote> accepts an optional parameter to enable verbose mode.

=cut

sub testremote {
  my $self    = shift;
  my $verbose = shift;

  $self->site( undef ) if $self->site;

  $ENV{FTP_PASSIVE} = 1 if ( $self->config->get( 'passive' ) );

  for my $site ( split( /\s+/, $self->config->get( 'remote' ) ) ) {

    $site .= '/' unless ( $site =~ m/\/$/ );

    print "Testing site: $site\n" if ( $verbose );

    if ( get( $site . 'authors/01mailrc.txt.gz' ) ) {
      $self->site( $site );

      print "\n$site selected.\n" if ( $verbose );
      last;
    }
  }

  croak "Unable to connect to any remote site" unless $self->site;

  return $self;
}

=head2 C<update_mirror>

This is a subclass of CPAN::Mini.

=cut

sub update_mirror {
  my $self    = shift;
  my %options = @_;

  croak 'Can not write to local: ' . $self->config->get( 'local' )
   unless ( -w $self->config->get( 'local' ) );

  $ENV{FTP_PASSIVE} = 1 if $self->config->get( 'passive' );

  $options{local}     ||= $self->config->get( 'local' );
  $options{trace}     ||= 0;
  $options{skip_perl} ||= $self->config->get( 'perl' ) || 1;

  $self->testremote( $options{trace} )
   unless ( $self->site || $options{remote} );
  $options{remote} ||= $self->site;

  $options{dirmode} ||= oct( $self->config->get( 'dirmode' )
     || sprintf( '0%o', 0777 & ~umask ) );

  CPAN::Mini->update_mirror( %options );
}

=head2 C<add>

Add a new module to the repository. The add method copies the module
file into the repository with the same structure as a CPAN site. For
example CPAN-Mini-Inject-0.01.tar.gz is copied to
MYCPAN/authors/id/S/SS/SSORICHE. add creates the required directory
structure below the repository.


=over 4

=item * module

The name of the module to add.

=item * version

The modules version number.

=item * modules

A reference to a hash of ModuleName => ModuleVersion pairs.  This can
be used in place of the single C<module> amd <version> arguments when
you have a distribution that contains multiple modules.

=item * authorid

CPAN author id. This does not have to be a real author id.

=item * file

The tar.gz of the module.

=back

=head3 Example, with a distribution that contains only one module:

  add( module => 'Module::Name',
       authorid => 'AUTHOR',
       version => 0.01,
       file => './Module-Name-0.01.tar.gz' );

=head3 Example, with a distribution that contains multiple modules:

  add( modules  => {
                     Animal        => '0.1',
                     Animal::Bear  => '1.2',
                     Animal::Zebra => '2.6',
                   },
       authorid => 'AUTHOR',
       file => './Zoo-3.2.tar.gz' );

=cut

sub add {
  my $self    = shift;
  my %options = @_;

  _optionchk( %options );  # Croaks if invalid!

  my $modulepath = $options{file};
  my $modulefile = basename $options{file};
  my $authorid   = uc $options{authorid};
  my $modules    = $options{modules} || { $options{module} => $options{version} };
  my $repository = $self->config->get( 'repository' );

  croak "No repository configured"
    unless ( $repository );

  croak "Can not write to repository: $repository"
    unless ( -w $repository );

  croak "Can not read module file: $options{file}"
    unless -r $options{file};

  $self->readlist unless exists( $self->{modulelist} );

  $self->{authdir} = $self->_authordir( $authorid, $repository );

  my $target
   = $repository
   . '/authors/id/'
   . $self->{authdir} . '/'
   . $modulefile;

  copy( $modulepath, dirname( $target ) )
   or croak "Copy failed: $!";

  $self->_updperms( $target );

  while (my ($modulename, $version) = each %$modules) {

      # remove old version from the list
      @{ $self->{modulelist} }
          = grep { $_ !~ m/\A$modulename\s+/ } @{ $self->{modulelist} };

      push(
          @{ $self->{modulelist} },
          _fmtmodule($modulename,
                     File::Spec::Unix->catfile(File::Spec->splitdir( $self->{authdir} ), $modulefile ),
                     $version )
      );
  }

  return $self;
}

=head2 C<inject>

Insert modules from the repository into the local CPAN::Mini mirror. inject
copies each module into the appropriate directory in the CPAN::Mini mirror
and updates the CHECKSUMS file.

Passing a value to C<inject> enables verbose mode, which lists each module
as it's injected.

=cut

sub inject {
  my $self    = shift;
  my $verbose = shift;

  my $dirmode = oct( $self->config->get( 'dirmode' ) )
   if ( $self->config->get( 'dirmode' ) );

  $self->readlist unless ( exists( $self->{modulelist} ) );

  my %updatedir;
  for my $modline ( @{ $self->{modulelist} } ) {
    my ( $module, $version, $file ) = split( /\s+/, $modline );
    my $target = $self->config->get( 'local' ) . '/authors/id/' . $file;
    my $source
     = $self->config->get( 'repository' ) . '/authors/id/' . $file;

    $updatedir{ dirname( $file ) } = 1;

    my $tdir = dirname $target;
    _make_path( $tdir, defined $dirmode ? { mode => $dirmode } : {} );
    copy( $source, $tdir )
     or croak "Copy $source to $tdir failed: $!";

    $self->_updperms( $target );
    print "$target ... injected\n" if $verbose;
  }

  for my $dir ( keys( %updatedir ) ) {
    my $authdir = $self->config->get( 'local' ) . "/authors/id/$dir";

    updatedir( $authdir );
    $self->_updperms( "$authdir/CHECKSUMS" );
  }

  $self->updpackages;
  $self->updauthors;

  return $self;
}

=head2 C<updpackages>

Update the CPAN::Mini mirror's modules/02packages.details.txt.gz with the
injected module information.

=cut

sub updpackages {
  my $self = shift;

  my @modules = sort( @{ $self->{modulelist} } );
  my $infile  = $self->_readpkgs;
  my %packages;

  # These need to be unique-per-package, with ones that come from the input
  # file being overridden.
  for my $line (@$infile, @modules) {
    my ($pkg) = split(/\s+/, $line, 2);
    $packages{$pkg} = $line;
  };

  $self->_writepkgs( [ sort values %packages ] );
}

=head2 C<updauthors>

Update the CPAN::Mini mirror's authors/01mailrc.txt.gz with
stub information should the author not actually exist on CPAN

=cut

sub updauthors {
  my $self = shift;

  my $repo_authors       = $self->_readauthors;
  my %author_ids_in_repo = map {
    my ( $id ) = $_ =~ /alias \s+ (\S+)/xms;
    $id => 1;
  } @$repo_authors;

  my @authors;
  my %authors_added;
  AUTHOR:
  for my $modline ( @{ $self->{modulelist} } ) {
    my ( $module, $version, $file ) = split( /\s+/, $modline );

    # extract the author from the path
    my @dirs = File::Spec->splitdir( $file );
    my $author = $dirs[2];

    next AUTHOR if defined $author_ids_in_repo{$author};
    next AUTHOR if defined $authors_added{$author};

    push @$repo_authors,
     sprintf( 'alias %-10s "Custom Non-CPAN author <CENSORED>"',
      $author );
    $authors_added{$author} = 1;
  }

  $self->_writeauthors( $repo_authors );

}

=head2 C<readlist>

Load the repository's modulelist.

=cut

sub _repo_file {
  File::Spec->catfile( shift->config->get( 'repository' ), @_ );
}

sub _modulelist { shift->_repo_file( 'modulelist' ) }

sub readlist {
  my $self = shift;

  $self->{modulelist} = undef;

  my $ml = $self->_modulelist;
  return $self unless -e $ml;

  open MODLIST, '<', $ml or croak "Can not read module list: $ml ($!)";
  while ( <MODLIST> ) {
    chomp;
    push @{ $self->{modulelist} }, $_;
  }
  close MODLIST;

  return $self;
}

=head2 C<writelist>

Write to the repository modulelist.

=cut

sub writelist {
  my $self = shift;

  croak 'Can not write module list: '
   . $self->config->get( 'repository' )
   . "/modulelist ERROR: $!"
   unless ( -w $self->{config}{repository} . '/modulelist'
    || -w $self->{config}{repository} );
  return $self unless defined( $self->{modulelist} );

  open( MODLIST,
    '>' . $self->config->get( 'repository' ) . '/modulelist' );
  for ( sort( @{ $self->{modulelist} } ) ) {
    chomp;
    print MODLIST "$_\n";
  }
  close( MODLIST );

  $self->_updperms(
    $self->config->get( 'repository' ) . '/modulelist' );

  return $self;
}

sub _updperms {
  my ( $self, $file ) = @_;

  chmod oct( $self->config->get( 'dirmode' ) ) & 06666, $file
   if $self->config->get( 'dirmode' );
}

sub _optionchk {
  my ( %options ) = @_;

  my @missing_options = grep { not $options{$_} } qw(authorid file);
  croak "Required option not specified: " . join ' ', @missing_options
      if @missing_options;

  my ($mod, $ver, $mods) = @options{qw(module version modules)};

  croak "Must specify either 'modules' or ('module' and 'version')"
      unless ( ($mod and $ver) or ($mods and not ($mod or $ver)) );

  croak "The modules argument must be a hashref"
      if $mods and ref $mods ne 'HASH';

  my @no_version = grep { not defined $mods->{$_} } keys %$mods;
  croak "Version number required for modules: ", join ' ', @no_version
      if @no_version;

}

sub _make_path {
  my $um = umask 0;
  make_path( @_ );
  umask $um;
}

sub _authordir {
  my ( $self, $author, $dir ) = @_;

  my @author
   = ( substr( $author, 0, 1 ), substr( $author, 0, 2 ), $author );

  my $dm = $self->config->get( 'dirmode' );
  my @new
   = _make_path( File::Spec->catdir( $dir, 'authors', 'id', @author ),
    defined $dm ? { mode => oct $dm } : {} );

  return return File::Spec->catdir( @author );
}

sub _fmtmodule {
  my ( $module, $file, $version ) = @_;
  my $fw = 38 - length $version;
  $fw = length $module if $fw < length $module;
  return sprintf "%-${fw}s %s  %s", $module, $version, $file;
}

sub _cfg { $_[0]->{config}{ $_[1] } }

sub _readpkgs {
  my $self = shift;

  my $gzread = gzopen(
    $self->config->get( 'local' )
     . '/modules/02packages.details.txt.gz', 'rb'
  ) or croak "Cannot open local 02packages.details.txt.gz: $gzerrno";

  my $inheader = 1;
  my @packages;
  my $package;

  while ( $gzread->gzreadline( $package ) ) {
    if ( $inheader ) {
      $inheader = 0 unless $package =~ /\S/;
      next;
    }
    chomp( $package );
    push( @packages, $package );
  }

  $gzread->gzclose;

  return \@packages;
}

sub _writepkgs {
  my $self = shift;
  my $pkgs = shift;

  my $gzwrite = gzopen(
    $self->config->get( 'local' )
     . '/modules/02packages.details.txt.gz', 'wb'
   )
   or croak
   "Can't open local 02packages.details.txt.gz for writing: $gzerrno";

  $gzwrite->gzwrite( "File:         02packages.details.txt\n" );
  $gzwrite->gzwrite(
    "URL:          http://www.perl.com/CPAN/modules/02packages.details.txt\n"
  );
  $gzwrite->gzwrite(
    'Description:  Package names found in directory $CPAN/authors/id/'
     . "\n" );
  $gzwrite->gzwrite( "Columns:      package name, version, path\n" );
  $gzwrite->gzwrite(
    "Intended-For: Automated fetch routines, namespace documentation.\n"
  );
  $gzwrite->gzwrite( "Written-By:   CPAN::Mini::Inject $VERSION\n" );
  $gzwrite->gzwrite( "Line-Count:   " . scalar( @$pkgs ) . "\n" );
  # Last-Updated: Sat, 19 Mar 2005 19:49:10 GMT
  $gzwrite->gzwrite( "Last-Updated: " . _fmtdate() . "\n\n" );

  $gzwrite->gzwrite( "$_\n" ) for ( @$pkgs );

  $gzwrite->gzclose;

}

sub _readauthors {
  my $self = shift;
  my $gzread
   = gzopen( $self->config->get( 'local' ) . '/authors/01mailrc.txt.gz',
    'rb' )
   or croak "Cannot open "
   . $self->config->get( 'local' )
   . "/authors/01mailrc.txt.gz: $gzerrno";

  my @authors;
  my $author;

  while ( $gzread->gzreadline( $author ) ) {
    chomp( $author );
    push( @authors, $author );
  }

  $gzread->gzclose;

  return \@authors;
}

sub _writeauthors {
  my $self    = shift;
  my $authors = shift;

  my $gzwrite
   = gzopen( $self->config->get( 'local' ) . '/authors/01mailrc.txt.gz',
    'wb' )
   or croak
   "Can't open local authors/01mailrc.txt.gz for writing: $gzerrno";

  $gzwrite->gzwrite( "$_\n" ) for ( sort @$authors );

  $gzwrite->gzclose;

}

sub _fmtdate {
  my @date = split( /\s+/, scalar( gmtime ) );
  return "$date[0], $date[2] $date[1] $date[4] $date[3] GMT";
}

=head1 See Also

L<CPAN::Mini>

=head1 Current Maintainer

Christian Walde C<< <walde.christian@googlemail.com> >>

=head1 Original Author

Shawn Sorichetti, C<< <ssoriche@cpan.org> >>

=head1 Acknowledgements

Special thanks to David Bartle, for bringing this module up
to date, and resolving the reported bugs.

Thanks to Jozef Kutej <jozef@kutej.net> for numerous patches.

=head1 Bugs

Please report any bugs or feature requests to
C<bug-cpan-mini-inject@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 Copyright & License

Copyright 2008-2009 Shawn Sorichetti, Andy Armstrong, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of CPAN::Mini::Inject
