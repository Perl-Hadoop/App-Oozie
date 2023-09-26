package App::Oozie::Deploy::Template::ttree;

use strict;
use warnings;
use parent qw( App::Oozie::Forked::Template::ttree );

sub new {
    my $class = shift;
    my $log_collector = shift;
    my $self  = $class->SUPER::new(
                    @_,
                );
    $self->{log_collector} = $log_collector,
    $self;
}

sub run {
    my $self = shift;
    my @arg  = @_;
    local @ARGV = @arg;
    $self->SUPER::run();
}

sub emit_warn {
    my $self = shift;
    my $msg  = shift;
    $self->{log_collector}->(
        level => 'warn',
        msg   => $msg,
    );
}

sub emit_log {
    my $self = shift;
    for my $msg ( @_ ) {
        $self->{log_collector}->(
            level => 'info',
            msg   => $msg,
        );
    }
}

1;

__END__
