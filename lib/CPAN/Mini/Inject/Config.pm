package CPAN::Mini::Inject::Config;

use strict;
use warnings;

use Carp;
use File::Spec::Functions qw(rootdir catfile);

=head1 NAME

CPAN::Mini::Inject::Config - Config for CPAN::Mini::Inject

=head1 VERSION

Version 0.34

=cut

our $VERSION = '0.34';

=head2 C<new>

=cut

sub new { bless { file => undef }, $_[0] }

=head2 C<< config_file( [FILE] ) >>

=cut

sub config_file {
  my ( $self, $file ) = @_;

  if ( @_ == 2 ) {
    croak( "Could not read file [$file]!" ) unless -r $file;
    $self->{file} = $file;
  }

  $self->{file};
}

=head2 C<< load_config() >>

loadcfg accepts a CPAN::Mini::Inject config file or if not defined
will search the following four places in order:

=over 4

=item * file pointed to by the environment variable MCPANI_CONFIG

=item * $HOME/.mcpani/config

=item * /usr/local/etc/mcpani

=item * /etc/mcpani

=back


loadcfg sets the instance variable cfgfile to the file found or undef if
none is found.

 print "$mcpi->{cfgfile}\n"; # /etc/mcpani

=cut

sub load_config {
  my $self = shift;

  my $cfgfile = shift || $self->_find_config;

  croak 'Unable to find config file' unless $cfgfile;
  $self->config_file( $cfgfile );

  return $cfgfile;
}

sub _find_config {
  my ( @files ) = (
    $ENV{MCPANI_CONFIG},
    (
      defined $ENV{HOME}
      ? catfile( $ENV{HOME}, qw(.mcpani config) )
      : ()
    ),
    catfile( rootdir(), qw(usr local etc mcpani) ),
    catfile( rootdir(), qw(etc mcpani) ),
  );

  for my $file ( @files ) {
    next unless defined $file;
    next unless -r $file;

    return $file;
  }

  return;
}

=head2 C<< parse_config() >>

parsecfg reads the config file stored in the instance variable cfgfile and
creates a hash in config with each setting.

  $mcpi->{config}{remote} # CPAN sites to mirror from.

parsecfg expects the config file in the following format:

 local: /www/CPAN
 remote: ftp://ftp.cpan.org/pub/CPAN ftp://ftp.kernel.org/pub/CPAN
 repository: /work/mymodules
 passive: yes
 dirmode: 0755

Description of options:

=over 4

=item * local

location to store local CPAN::Mini mirror (*REQUIRED*)

=item * remote

CPAN site(s) to mirror from. Multiple sites can be listed space separated.
(*REQUIRED*)

=item * repository

Location to store modules to add to the local CPAN::Mini mirror.

=item * passive

Enable passive FTP.

=item * dirmode

Set the permissions of created directories to the specified mode. The default
value is based on umask if supported.

=back

If either local or remote are not defined parsecfg croaks.

=cut

sub parse_config {
  my $self = shift;

  my $file = shift;

  my %required = map { $_, 1 } qw(local remote);

  $self->load_config( $file ) unless $self->config_file;

  if ( -r $self->config_file ) {
    open my ( $fh ), "<", $self->config_file
     or croak( "Could not open config file: $!" );

    while ( <$fh> ) {
      next if /^\s*#/;
      $self->{$1} = $2 if /^\s*([^:\s]+)\s*:\s*(.*?)\s*$/;
      delete $required{$1} if defined $required{$1};
    }

    close $fh;

    croak 'Required parameter(s): '
     . join( ' ', keys %required )
     . ' missing.'
     if keys %required;
  }

  return $self;
}

=head2 C<< get( DIRECTIVE ) >>

Return the value for the named configuration directive.

=cut

sub get { $_[0]->{ $_[1] } }

=head2 C<< set( DIRECTIVE, VALUE ) >>

Sets the value for the named configuration directive.

=cut

sub set { $_[0]->{ $_[1] } = $_[2] }

=head1 CURRENT MAINTAINER

Christian Walde C<< <walde.christian@googlemail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cpan-mini-inject@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=cut

1;
