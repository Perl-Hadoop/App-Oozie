package App::Oozie;

use 5.014;
use strict;
use warnings;

# VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use Moo;
use MooX::Options prefer_commandline => 0,
                  protect_argv       => 0,
                  usage_string       => <<'USAGE',
Usage: %c %o action
USAGE
;

use App::Oozie::Util::Plugin qw( find_plugins );

with qw(
    App::Oozie::Role::Log
);

option debug => (
    is  => 'rw',
    doc => 'Enable debug messages',
);

sub run {
    my $self   = shift;
    my $debug  = $self->debug;
    my $logger = $self->logger;

    my $action_to_class = find_plugins('App::Oozie::Action');

    if ( $debug ) {
        $logger->debug( sprintf "Found: %s", $_ )
            for sort keys %{ $action_to_class };
    }

    my @valid = sort keys %{ $action_to_class };

    my $action = shift( @ARGV ) || do {
        my $msg = sprintf "Please specify an action. Possible actions are any one of:\n\n%s\n",
                    join q{}, map { "\t$_\n" } @valid
        ;
        $self->options_usage(1, $msg);
    };

    $action =~ s{[_]}{-}xmsg;

    my $class = $action_to_class->{ $action } || do {
        my $msg = sprintf "The specified action `%s` is invalid. Possible actions are any one of:\n\n%s\n",
                    $action,
                    join q{}, map { "\t$_\n" } @valid
        ;
        $self->options_usage(1, $msg);
    };

    my @cmd = (
        $^X,
        ( map { '-I' . $_ } @INC ),
        '-M' . $class,
        '-E', "$class->new_with_options->run",
        '--',
        @ARGV
    );

    if ( $debug ) {
        require Data::Dumper;
        my $d = Data::Dumper->new(
                    [  \@cmd ],
                    [qw( cmd )]
                )->Indent( 0 );
        $logger->debug( sprintf "Executing: %s", $d->Dump );
    }

    exec @cmd;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie - Tooling/wrappers for Oozie job deployment and scheduling

=head1 SYNOPSIS

=head1 DESCRIPTION

Oozie is a workflow scheduler system to manage Apache Hadoop jobs.
Oozie Workflow jobs are Directed Acyclical Graphs (DAGs) of actions.

The sets of tools in this package tries to make it easier to generate,
deploy and schedule Oozie application specs and files.

=head1 Methods

=head2 debug

=head2 run

=head1 SEE ALSO

L<https://oozie.apache.org>.

L<App::Oozie::Deploy>, L<App::Oozie::Run>, L<App::Oozie::Update::Coordinator>,
L<http://oozie.apache.org>.

=cut

