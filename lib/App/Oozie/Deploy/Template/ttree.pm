package App::Oozie::Deploy::Template::ttree;

use strict;
use warnings;
use parent qw( App::Oozie::Forked::Template::ttree );

# VERSION

sub new {
    my($class, $log_collector, @pass_through) = @_;
    my $self  = $class->SUPER::new(
                    @pass_through,
                );
    $self->{log_collector} = $log_collector;
    return $self;
}

sub run {
    my($self, @args) = @_;
    local @ARGV = @args;
    return $self->SUPER::run();
}

sub emit_warn {
    my($self, $msg) = @_;
    return$self->{log_collector}->(
        level => 'warn',
        msg   => $msg,
    );
}

sub emit_log {
    my($self, @msgs) = @_;
    for my $msg ( @msgs ) {
        $self->{log_collector}->(
            level => 'info',
            msg   => $msg,
        );
    }
    return;
}

1;

__END__
