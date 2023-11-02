package App::Oozie::Role::Info;

use 5.014;
use strict;
use warnings;

# VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use Moo::Role;
use Ref::Util qw( is_arrayref );

with qw(
    App::Oozie::Role::Log
);

sub log_versions {
    my $self      = shift;
    my $log_level = shift || 'debug';
    my $me        = ref $self;
    my @classes   = ( [ $me, $self->VERSION ] );

    my $base_class = do {
        no strict qw(refs);
        my @isa =   grep { $_ ne $me }
                    map  {
                        is_arrayref $_ ? @{ $_ } : $_
                    }
                    @{ $me . '::ISA' };
        @isa ? $isa[0] : ();
    };

    if ( $base_class ) {
        push @classes, [ $base_class, $base_class->VERSION ];
    }

    for my $tuple ( @classes ) {
        my($name, $v) = @{ $tuple };
        my $msg = defined $v
                ? sprintf 'Running under %s %s', $name, $v
                : sprintf 'Running under %s', $name
                ;
        $self->logger->$log_level( $msg );
    }

    return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Role::Info - Helper to gather information about the tooling.

=head1 SYNOPSIS

    use Moo;
    with qw(
        App::Oozie::Role::Info
    );
    sub method {
        my $self = shift;
        $self->log_versions if $self->verbose;
    }

=head1 DESCRIPTION

Helper to gather information about the tooling.

=head1 Methods

=head2 log_versions

=head1 SEE ALSO

L<App::Oozie>.

=cut
