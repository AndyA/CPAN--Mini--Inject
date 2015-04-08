package MyBuilder;
use strict;

use base qw( Module::Build );

use FindBin;
use Cwd qw(realpath);
use File::Spec::Functions;

use Pod::Markdown::Github;

sub create_build_script {
  my ( $self, @args ) = @_;
  $self->_auto_mm;
  return $self->SUPER::create_build_script( @args );
}

sub _auto_mm {
  my $self = shift;
  my $mm   = $self->meta_merge;
  my @meta = qw( homepage bugtracker MailingList repository );
  for my $meta ( @meta ) {
    next if exists $mm->{resources}{$meta};
    my $auto = "_auto_$meta";
    next unless $self->can( $auto );
    my $av = $self->$auto();
    $mm->{resources}{$meta} = $av if defined $av;
  }
  $self->meta_merge( $mm );
}

sub _auto_repository {
  my $self = shift;
  if ( -d '.svn' ) {
    my $info = `svn info .`;
    return $1 if $info =~ /^URL:\s+(.+)$/m;
  }
  elsif ( -d '.git' ) {
    my $info = `git remote -v`;
    return unless $info =~ /^origin\s+(.+)\s\(\w+\)$/m;
    my $url = $1;
    # Special case: patch up github URLs
    $url =~ s!^git\@github\.com:!git://github.com/!;
    return $url;
  }
  return;
}

sub _auto_bugtracker {
  'http://rt.cpan.org/NoAuth/Bugs.html?Dist=' . shift->dist_name;
}

sub ACTION_testauthor {
  my $self = shift;
  $self->test_files( 'xt/author' );
  $self->ACTION_test;
}

sub ACTION_critic {
  exec qw( perlcritic -1 -q -profile perlcriticrc lib/ ), glob 't/*.t';
}

sub ACTION_tags {
  exec(
    qw(
     ctags -f tags --recurse --totals
     --exclude=blib
     --exclude=.svn
     --exclude='*~'
     --languages=Perl
     t/ lib/
     )
  );
}

sub ACTION_tidy {
  my $self = shift;

  my @extra = qw( Build.PL );

  my %found_files = map { %$_ } $self->find_pm_files,
   $self->_find_file_by_type( 'pm', 't' ),
   $self->_find_file_by_type( 'pm', 'inc' ),
   $self->_find_file_by_type( 't',  't' );

  my @files = ( keys %found_files,
    map { $self->localize_file_path( $_ ) } @extra );

  for my $file ( @files ) {
    system 'perltidy', '-b', $file;
    unlink "$file.bak" if $? == 0;
  }
}

sub ACTION_docs {

  my $self = shift;

  my $inject_pm   = catfile($FindBin::Bin, "lib", "CPAN", "Mini", "Inject.pm");
  my $readme_md   = catfile($FindBin::Bin, "README.md");

  my $parser = Pod::Markdown::Github->new( perldoc_url_prefix => 'metacpan' );

  open my $in_file,  "<", $inject_pm or die "Failed to open '$inject_pm': $!\n";
  open my $out_file, ">", $readme_md or die "Failed to open '$readme_md': $!\n";

  $parser->output_fh($out_file);
  $parser->parse_file($in_file);

  close $out_file;
  close $in_file;

  return $self->SUPER::ACTION_docs;
}

1;
