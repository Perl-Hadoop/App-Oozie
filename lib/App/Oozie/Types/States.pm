## no critic (RequireStrictDeclarations ProhibitUselessNoCritic)
package App::Oozie::Types::States;

use 5.014;
use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;

use App::Oozie::Constants qw(
    OOZIE_STATES_RERUNNABLE
    OOZIE_STATES_RUNNING
);

BEGIN {
    extends 'Types::Standard';
}

my $StateRerunnableEnum = declare StateRerunnableEnum => as Enum[ OOZIE_STATES_RERUNNABLE ];

declare IsOozieStateRerunnable => as ArrayRef[ $StateRerunnableEnum, 1 ];

my $StateRunningEnum = declare StateRunningEnum => as Enum[ OOZIE_STATES_RUNNING ];

declare IsOozieStateRunning => as ArrayRef[ $StateRunningEnum, 1 ];

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Types::States - Internal types.

=head1 SYNOPSIS

    use App::Oozie::Types::States qw( IsOozieStateRerunnable );

=head1 DESCRIPTION

Internal types.

=head1 Types

=head2 IsOozieStateRerunnable

=head2 IsOozieStateRunning

=head2 StateRerunnableEnum

=head2 StateRunningEnum

=head1 SEE ALSO

L<App::Oozie>.

=cut
