package App::Oozie::Deploy::Validate::DAG::Vertex;

use 5.014;
use strict;
use warnings;

# VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];
use overload
    '""' => \&stringify,
    'eq' => \&is_eq,
    'ne' => \&is_ne,
;

use Carp qw( confess );
use Moo;
use Types::Standard qw( HashRef Str );

has name => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has data => (
    is  => 'rw',
    isa => HashRef,
);

sub stringify {
    return shift->{name};
}

sub is_eq {
    my ($v1, $v2) = @_;
    return ((ref $v1 ? $v1->{name} : $v1) eq (ref $v2 ? $v2->{name} : $v2));
}

sub is_ne {
    my ($v1, $v2) = @_;
    return ((ref $v1 ? $v1->{name} : $v1) ne (ref $v2 ? $v2->{name} : $v2));
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Deploy::Validate::DAG::Vertex - Part of the Oozie workflow DAG validator.

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

TBD

=head1 Methods

=head2 is_eq

=head2 is_ne

=head2 stringify

=head1 SEE ALSO

L<App::Oozie>.

=cut
