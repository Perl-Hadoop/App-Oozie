package App::Oozie::Util::Log4perl;

use 5.014;
use strict;
use warnings;

use App::Oozie::Util::Plugin qw(
    find_files_in_inc
    find_plugins
);
use Moo;

# TODO
sub find_template {
    my $self = shift;
    my $type = shift || 'simple';

    my @found = find_files_in_inc('App/Oozie/Util/Log4perl/Templates', 'l4p');
    my %tmpl = map { @{ $_ }{qw/ name abs_path /} } @found;

    return $tmpl{ $type } || $tmpl{simple} || die "No log4perl template file was found";
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Util::Log4perl - Helper for handling the Log4perl template.

=head1 SYNOPSIS

    use App::Oozie::Util::Log4perl;
    my $file = App::Oozie::Util::Log4perl->new->find_template;

=head1 DESCRIPTION

Internal module.

=head1 Methods

=head2 find_template

=head1 SEE ALSO

L<App::Oozie>.

=cut
