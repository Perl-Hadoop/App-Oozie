package App::Oozie::Role::Fields::Generic;

use 5.014;
use strict;
use warnings;

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Constants qw(
    DEFAULT_TIMEOUT
);

use Moo::Role;
use MooX::Options;
use Types::Standard qw( Int );

option dryrun => (
    is       => 'rw',
    short    => 'd',
    doc      => 'Do not perform the actions (also call dry-run versions of the underlying commands)',
);

option force => (
    is       => 'rw',
    short    => 'f',
    doc      => 'force a run even though some errors were encountered',
);

option max_retry => (
    is       => 'rw',
    isa      => Int,
    default  => sub { 3 },
    doc      => 'Maximum number of retries for various function calls',
);

option timeout => (
    is      => 'rw',
    default => sub { DEFAULT_TIMEOUT },
    isa     => Int,
    format  => 'i',
    doc     => sprintf( 'The timeout value in seconds for the system calls. Defaults to %s seconds',
                            DEFAULT_TIMEOUT ),
);

option verbose => (
    is    => 'rw',
    short => 'v',
    doc   => 'Enable verbose messages',
);

has effective_username => (
    is      => 'ro',
    default => sub {
        (getpwuid $<)[0]
            || die "Unable to locate the effective user name";
    },
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

Overridable generic fields for internal programs/libs.

=head1 SYNOPSIS

    use Moo::Role;
    use MooX::Options;
    with 'App::Oozie::Role::Fields::Generic';

=head1 DESCRIPTION

This is a Role to be consumed by Oozie tooling classes and
defines various fields.

=head1 Accessors

=head2 Overridable from cli

=head3 dryrun

=head3 force

=head3 max_retry

=head3 timeout

=head3 verbose

=head2 Overridable from sub-classes

=head3 effective_username

=head1 SEE ALSO

L<App::Oozie>.

=cut
