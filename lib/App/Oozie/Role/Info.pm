package App::Oozie::Role::Info;

use 5.014;
use strict;
use warnings;

# VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use Moo::Role;

with qw(
    App::Oozie::Role::Log
);

sub log_versions {
    my $self      = shift;
    my $log_level = shift || 'debug';
    my $me        = ref $self;
    my @classes   = ( [ $me, $self->VERSION ] );

    if ( $me ne __PACKAGE__ ) {
        push @classes, [ __PACKAGE__, __PACKAGE__->VERSION ];
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
