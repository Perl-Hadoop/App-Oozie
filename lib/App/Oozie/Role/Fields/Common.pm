package App::Oozie::Role::Fields::Common;

use 5.014;
use strict;
use warnings;

# VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Types::Common qw( IsUserName );
use App::Oozie::Constants qw(
    DEFAULT_CLUSTER_NAME
    DEFAULT_HDFS_WF_PATH
);
use Moo::Role;
use MooX::Options;
use Types::Standard qw( Bool Str );

with qw(
    App::Oozie::Role::Fields::Generic
    App::Oozie::Role::Fields::Path
    App::Oozie::Role::Fields::Objects
);

option cluster_name => (
    is      => 'rw',
    isa     => Str,
    default => sub { DEFAULT_CLUSTER_NAME },
    format  => 's',
    doc     => 'The Hadoop cluster name',
);

option username => (
    is      => 'rw',
    isa     => IsUserName,
    short   => 'user',
    format  => 's',
    doc     => 'User name under which the job should be submitted. Not set by default and commands will be executed as the effective user',
);

has execute_as_someone_else => (
    is      => 'ro',
    isa     => Bool,
    default => sub {
        my $self = shift;
        my $deployment_user = $self->username;
        return $deployment_user
                && $deployment_user ne $self->effective_username ? 1 : 0;
    },
    lazy => 1,
);

option oozie_uri => (
    is      => 'ro',
    format  => 's',
    doc     => 'The address to the oozie instance',
    lazy    => 1,
    default => sub { shift->oozie->oozie_uri },
);

option default_hdfs_destination => (
    is      => 'rw',
    format  => 's',
    default => sub { DEFAULT_HDFS_WF_PATH },
    doc     => 'The HDFS destination for the compiled Oozie workflows',
);

option oozie_basepath => (
    is      => 'rw',
    format  => 's',
    default => sub {shift->default_hdfs_destination},
    doc     => 'The HDFS destination for the compiled Oozie workflows',
    lazy    => 1,
);

has secure_cluster => (
    is      => 'rw',
    default => sub { 0 },
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Role::Fields::Common - Overridable common fields for internal programs/libs.

=head1 SYNOPSIS

    use Moo::Role;
    use MooX::Options;
    with 'App::Oozie::Role::Fields::Common';

=head1 DESCRIPTION

This is a Role to be consumed by Oozie tooling classes and
defines various fields.

=head1 Accessors

=head2 Overridable from cli

=head3 cluster_name

=head3 default_hdfs_destination

=head3 oozie_basepath

=head3 oozie_uri

=head3 username

=head2 Overridable from sub-classes

=head3 execute_as_someone_else

=head3 secure_cluster

=head1 SEE ALSO

L<App::Oozie>.

=cut
