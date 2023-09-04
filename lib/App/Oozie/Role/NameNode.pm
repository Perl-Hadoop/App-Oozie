package App::Oozie::Role::NameNode;

use 5.010;
use strict;
use warnings;
use namespace::autoclean -except => [qw/_options_data _options_config/];

use Log::Log4perl;
use Moo::Role;
use MooX::Options;
use Net::Hadoop::YARN::NameNode::JMX;
use App::Oozie::Types::Common  qw( ArrayRef Str );
use App::Oozie::Constants qw(
    DEFAULT_NAMENODE_RPC_PORT
);

option yarn_namenodes => (
    is       => 'rw',
    isa      => ArrayRef[Str],
    format   => 's@',
    doc      => 'YARN NameNode pair',
    optional => 1,
);

has active_namenode => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        my $opt = $self->yarn_namenodes;
        my $nn = Net::Hadoop::YARN::NameNode::JMX->new( $opt ? @{ $opt } : () );
        return $nn->active_namenode;
    },
    lazy => 1,
);

has namenode_rpc_port => (
    is      => 'rw',
    default => sub { DEFAULT_NAMENODE_RPC_PORT },
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Role::NameNode - Hadoop NameNode related accessors.

=head1 SYNOPSIS

    use Moo::Role;
    use MooX::Options;
    with 'App::Oozie::Role::NameNode';

=head1 DESCRIPTION

This is a Role to be consumed by Oozie tooling classes and
defines various fields.

=head1 Accessors

=head2 Overridable from cli

=head3 yarn_namenodes

=head2 Overridable from sub-classes

=head3 active_namenode

=head3 namenode_rpc_port

=head1 SEE ALSO

L<App::Oozie>.

=cut

