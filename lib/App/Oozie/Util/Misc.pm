package App::Oozie::Util::Misc;

use 5.010;
use strict;
use warnings;
use parent qw( Exporter );

our @EXPORT_OK = qw(
    remove_newline
    resolve_tmp_dir
);

sub remove_newline { my $s = shift; $s =~ s{\n+}{ }xmsg; $s }

sub resolve_tmp_dir {
    # Wokaround "/tmp is an existing symbolic link" error.
    # Happens in EMR for example.
    #
    my $tmp = $ENV{TMPDIR} || $ENV{TMP} || '/tmp';
    return $tmp if ! -l $tmp;
    my $real = readlink $tmp;
    return $real;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Util::Misc - Miscellaneous utility functions

=head1 SYNOPSIS

    use App::Oozie::Util::Misc qw( remove_newline );

=head1 DESCRIPTION

Internal module.

=head1 Methods

=head2 remove_newline

=head2 resolve_tmp_dir

=head1 SEE ALSO

L<App::Oozie>.

=cut
