package App::Oozie::Role::Fields::Path;

use 5.014;
use strict;
use warnings;

# VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Types::Common qw( IsExecutable IsFile IsDir );
use Moo::Role;
use MooX::Options;
use Types::Standard qw( Str );

option oozie_cli => (
    is       => 'rw',
    isa      => IsExecutable,
    format   => 's',
    doc      => 'Full path to the oozie client binary',
    default  => sub { '/usr/bin/oozie' },
);

option oozie_client_jar => (
    is       => 'rw',
    isa      => IsFile,
    format   => 's',
    doc      => 'Full path to the Oozie client jar containing the XML schemas',
    default  => sub { '/usr/lib/oozie/lib/oozie-client.jar' },
);

option local_oozie_code_path => (
    is       => 'rw',
    isa      => IsDir,
    format   => 's',
    doc      => 'Full path to the local base location of the workflows',
    required => 1,
);

option template_namenode => (
    is       => 'rw',
    isa      => Str,
    format   => 's',
    doc      => 'The value of the nameNode variable set in Oozie job config',
    default  => sub { 'hdfs://nameservice1' },
    required => 1,
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Role::Fields::Path - Overridable paths for internal programs/libs.

=head1 SYNOPSIS

    use Moo::Role;
    use MooX::Options;
    with 'App::Oozie::Role::Fields::Path';

=head1 DESCRIPTION

This is a Role to be consumed by Oozie tooling classes and
defines various fields.

=head1 Accessors

=head2 Overridable from cli

=head3 oozie_cli

=head3 oozie_client_jar

=head3 local_oozie_code_path

=head1 SEE ALSO

L<App::Oozie>.

=cut

