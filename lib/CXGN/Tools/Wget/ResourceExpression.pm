=head1 NAME

CXGN::Tools::Wget::ResourceExpression - fetch, filter, and compose
remote and local files based on string expressions

=head1 SYNOPSIS

  use CXGN::Tools::Wget::ResourceExpression qw/ fetch_expression /;

  my $file = fetch_expression( <<'', $destination_file );
  cat( unzip( http://example.com/foo.zip ), gunzip( http://example2.com/bar.gz ) )

=head1 FUNCTIONS

All functions below are EXPORT_OK.

=cut

package CXGN::Tools::Wget::ResourceExpression;
use strict;
use warnings;

use File::Temp 'tempfile';

use base 'Exporter';
our @EXPORT_OK = (
    'fetch_expression',
    'test_fetch_expression',
);

use CXGN::Tools::Run;
use CXGN::Tools::Wget;

=head2 fetch_expression( $expression, $destination_file )

Fetch an expression, which is just composed of operator calls like
unzip(), and URLs.

Example expression:

  cat( http://google.com, http://solgenomics.net )

Will fetch Google and SGN front page HTML and concatenate it.

=cut

sub fetch_expression {
  my ( $expression, $destfile ) = @_;

  my $parse_tree = _parse_expression( $expression ); #< dies on parse error

  #now go depth-first down the tree and evaluate it
  # note that if no dest file is provided, _evaluate()
  # will make a temp file
  return _evaluate( $parse_tree, 0, $destfile);
}

=head2 test_fetch_expression

Same as C<fetch_expression> above, but does not download the full
data, just returns true if the expression appears good (i.e. all the
URLs and operators are correct), false otherwise.

=cut

sub test_fetch_expression {
    my ( $expression ) = @_;

    my $parse_tree = _parse_expression( $expression ); #< dies on parse error

    #now go depth-first down the tree and evaluate it
    # note that if no dest file is provided, _evaluate()
    # will make a temp file
    my $file = _evaluate( $parse_tree, 1);
    unlink $file;
    return 1;
}

#recursively evaluate one of these little parse trees,
#converting the URLs and function calls into filenames
sub _evaluate {
  my ($tree,$testing,$destfile) = @_;

  #if we haven't been given a destination file, make a temporary one
  $destfile ||= do {
    my (undef,$f) = tempfile( File::Spec->catfile( CXGN::Tools::Wget->temp_root_dir(), 'cxgn-tools-wget-resourcefile-XXXXXX' ), UNLINK => 0);
    #cluck "made tempfile $f\n";
    $f
  };

  if( $tree->isa('call') ) {
    # evaluate each argument, then call the function on it
    # these evaluations are each going to make a temp file
    my ($func,@args) = @$tree;
    @args = map _evaluate($_,$testing), @args;

    #now apply the function to each of these files and make a composite file
    no strict 'refs';
    "op_$func"->($destfile,$testing,@args);

    #delete each of the argument temp files
    unlink @args;
  }
  else {
    #fetch the URL pointed to
    ref $tree and die "assertion failed, parse tree should only have one element here";
    #warn "fetching $tree\n";
    CXGN::Tools::Wget::wget_filter($tree,$destfile, {cache => 0, test_only => $testing});
  }
  return $destfile;
}
use Carp::Always;

our @symbols;
# parse the expression and return a tree representation of it
sub _parse_expression {
  my ( $exp ) = @_;

#  $exp = 'foo';
  #ignore all whitespace
  $exp =~ s/\s//g;

  #split the expression into symbols
  @symbols = ($exp =~ /[^\(\),]+|./g);

  my $parse_tree =  _parse_subexpression();

  return $parse_tree;
}


#recursively parse the expression
# _parse_expression and _parse_func make a simple recursive-descent parser
sub _parse_subexpression {
  #beginning of a tuple
  if( $symbols[0] =~ /^\S{2,}$/ ) {
    if( $symbols[1] && $symbols[1] eq '(' ) {
      return _parse_func();
    } else {
      return shift @symbols;
    }
  }
  else {
    die "unexpected symbol '$symbols[0]'";
  }
}
sub _parse_func {
  my $funcname = shift @symbols;
  my $leftparen = shift @symbols;
  $leftparen eq '('
    or die "unexpected symbol '$leftparen'";

  my @args = _parse_subexpression;

  while( $symbols[0] ne ')' ) {
    if( $symbols[0] eq ',' ) {
      shift @symbols;
      push @args, _parse_subexpression;
    }
    else {
      die "unexpected symbol '$symbols[0]'";
    }
  }
  shift @symbols; #< shift off the )

  #check that this is a valid function name
  __PACKAGE__->can("op_$funcname") or die "unknown resource file op '$funcname'";

  return bless [ $funcname, @args ], 'call';
}

#### FILE OPERATION FUNCTIONS, ADD YOUR OWN BELOW HERE ########
#
# 1. each function takes a destination file name, then a list of
#    filenames as arguments.  It does its operation on the argument files,
#    and writes to the destination file
#
# 2. functions are NOT allowed to modify any files except their
#    destination file
#
# 3. functions should die on error

sub op_gunzip {
  my ($destfile,$testing,@files) = @_;

#  warn "gunzip ".join(',',@files)."> $destfile\n";
  unless( $testing ) {
    my $gunzip = CXGN::Tools::Run->run('gunzip', -c => @files,
				       { out_file => $destfile }
				      );
  } else {
      open my $f, '>>', $destfile;
  }
}

sub op_unzip {
    my ( $destfile, $testing, @files ) = @_;
    unless( $testing ) {
        # trunc the destfile
        { open my $f, '>', $destfile }
        # then unzip into it with append
        `unzip -qc $_ >> $destfile` for @files;
    } else {
        open my $f, '>>', $destfile;
    }
}

sub op_cat {
  my ($destfile,$testing,@files) = @_;
#  warn "cat ".join(',',@files)." > $destfile\n";
  my $cat = CXGN::Tools::Run->run('cat', @files,
				  { out_file => $destfile }
				 );
}

1;
