package App::Oozie::Role::Log;

use 5.014;
use strict;
use warnings;
use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Util::Log4perl;
use Log::Log4perl;
use Moo::Role;

sub logger {
    state $init;
    state $logger;

    my $self = shift;

    return $logger if $logger;

    if ( ! $init ) {
        Log::Log4perl->init( App::Oozie::Util::Log4perl->new->find_template );
        $init++;
    }

    $logger //= Log::Log4perl->get_logger;

    return $logger;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Role::Log - Internal logger.

=head1 SYNOPSIS

    use Moo::Role;
    with 'App::Oozie::Role::Log';

    sub some_method {
        my $self = shift;
        $self->logger->info("Hello");
    }

=head1 DESCRIPTION

This is a Role to be consumed by Oozie tooling classes and
defines various fields.

=head1 Methods

=head2 logger

=head1 SEE ALSO

L<App::Oozie>.

=cut
