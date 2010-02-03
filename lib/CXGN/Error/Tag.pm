
=head1 NAME

CXGN::Error::Tag

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Allows you to send tagged error messages to STDERR. We may someday want to
grep through error logs to find these tagged messages.

=head2 dbg

Short for "debug". Prints a message to STDERR with tag markers around it,
but only if we are NOT the production server. a shorter way to do the common 
debugging technique of 

    print STDERR 'i got here!';
 
And, it won't matter too much if you forget to comment it out later.

    use CXGN::Error::Tag ('dbg','wrn');
    dbg;#prints just empty dbg tags, as long as you are not a production server.
    dbg('my debug message');#prints a message in dbg tags 
    dbg('my debug message','tag');#prints a message in tags of your choosing

=head2 wrn

Short for "warn". Does a warn with your message, putting tag markers around it. 
The warn command (or this command) will sometimes behave a bit differently from merely
printing to STDERR. For instance, on our web server, "warn" also usually prints
a timestamp to the log.

    use CXGN::Error::Tag ('dbg','wrn');
    wrn;#prints just empty wrn tags 
    wrn('my debug message');#prints a message in wrn tags  
    wrn('my debug message','tag');#prints a message in tags of your choosing 

=cut

package CXGN::Error::Tag;

use strict;
use CXGN::VHost;
BEGIN{our @EXPORT_OK=('dbg','wrn');}
our @EXPORT_OK;
use base qw/Exporter/;

our($open,$close)=('<[',']>');

sub dbg
{
    my($error,$tag)=@_;
    $error||='';
    $tag||='dbg';
    my $conf=CXGN::VHost->new();
    unless($conf->get_conf('production_server'))
    {
        print STDERR "$open$tag$close$error$open/$tag$close\n"
    }
}

sub wrn
{
    my($error,$tag)=@_;
    $error||='';
    $tag||='wrn';
    warn"$open$tag$close$error$open/$tag$close";
}

1;
