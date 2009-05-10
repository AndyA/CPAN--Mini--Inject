package CPANServer;

use strict;
use warnings;
use base qw(HTTP::Server::Simple::CGI);
use File::Spec::Functions;

sub handle_request {
  my $self=shift;
  my $cgi=shift;

  my $file=(split('/',$cgi->path_info))[-1];
  $file='index.html' unless($file);
  open(INFILE,catfile('t','html',$file)) or die "Can't open file $file: $@";
  print $_ while(<INFILE>);
  close(INFILE);
}

our %env_mapping =
    ( protocol => "SERVER_PROTOCOL",
      localport => "SERVER_PORT",
      localname => "SERVER_NAME",
      path => "PATH_INFO",
      request_uri => "REQUEST_URI",
      method => "REQUEST_METHOD",
      peeraddr => "REMOTE_ADDR",
      peername => "REMOTE_HOST",
      query_string => "QUERY_STRING",
    );

sub setup {
  no warnings 'uninitialized';
  my $self = shift;

  while ( my ($item, $value) = splice @_, 0, 2 ) {
    if ( $self->can($item) ) {
      $self->$item($value);
    }
    if ( my $k = $env_mapping{$item} ) {
      $ENV{$k} = $value;
    }
  }
}


1;
