## no critic (RequireStrictDeclarations ProhibitUselessNoCritic)
package App::Oozie::Constants;

use 5.010;
use strict;
use warnings;
use parent qw( Exporter );

use constant OOZIE_STATES_RERUNNABLE => qw(
    KILLED
    SUSPENDED
    FAILED
);

use constant OOZIE_STATES_RUNNING => qw(
    RUNNING
    SUSPENDED
    PREP
);

use constant {
    DEFAULT_TZ           => 'CET',
    DEFAULT_WEBHDFS_PORT => 14000,
};

our @EXPORT_OK = qw(
    DEFAULT_TZ
    DEFAULT_WEBHDFS_PORT
    OOZIE_STATES_RERUNNABLE
    OOZIE_STATES_RUNNING
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Constants - Internal constants.

=head1 SYNOPSIS

    use App::Oozie::Constants qw( DEFAULT_TZ );

=head1 DESCRIPTION

Internal constants.

=head1 Constants

=head2 DEFAULT_TZ

=head2 DEFAULT_WEBHDFS_PORT

=head2 OOZIE_STATES_RERUNNABLE

=head2 OOZIE_STATES_RUNNING

=head1 SEE ALSO

L<App::Oozie>.

=cut
