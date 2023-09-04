package App::Oozie::Deploy::Validate::Meta;

use 5.010;
use strict;
use warnings;
use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Serializer;
use App::Oozie::Types::Workflow qw(
    WorkflowMeta
    WorkflowMetaOrDummy
);
use App::Oozie::Constants qw( DEFAULT_META_FILENAME );
use Moo;
use MooX::Options;
use Types::Standard qw( InstanceOf Str );

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Generic
);

has file => (
    is      => 'rwp',
    isa     => Str,
    default => sub { DEFAULT_META_FILENAME },
);

has coord_directive => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'coordinator_deploy_meta_lineage' }, # created on the fly
);

has coord_directive_var => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'COORD_META_FILE_PATH' },
);

has wf_directive => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'workflow_deploy_meta_lineage' }, # created on the fly
);

has wf_directive_var => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'WF_META_FILE_PATH' },
);

has serializer => (
    is      => 'ro',
    isa     => InstanceOf['App::Oozie::Serializer'],
    default => sub {
        App::Oozie::Serializer->new(
            enforce_type => WorkflowMetaOrDummy,
            format       => 'yaml',
            slurp        => 1,
        );
    },
);

sub is_invalid_workflow_meta {
    my $self  = shift;
    my $input = shift;
    my $type  = WorkflowMeta;

    my($reason, $what);
    eval {
        $what   = ref $input ? $input : $self->serializer->decode( $input );
        $reason = $type->validate_explain( $what );
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        $reason = ref $eval_error ? $eval_error : [ $eval_error ];
    };

    if ( $reason && $what && $self->verbose ) {
        require Data::Dumper;
        my $d = Data::Dumper->new([ $what], ['*META_YML'] );
        $self->logger->debug( sprintf'Raw decoded content without type checks: %s', $d->Dump );
    }

    return $reason;
}

sub maybe_decode {
    my $self      = shift;
    my $meta_file = shift || $self->file;
    my $logger    = $self->logger;
    my $rs;
    eval {
        $rs = $self->serializer->decode( $meta_file );
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        $logger->error( sprintf 'Meta file %s validation failed: %s', $meta_file, $eval_error );
        return;
    };

    return if ! $rs;

    if ( my $reason = $self->is_invalid_workflow_meta( $rs ) ) {
        $logger->info(
            sprintf 'Meta file %s exists, but seems to be an invalid one. Ignoring%s.',
                        $meta_file,
                        $self->verbose ? '' : ' (enable --verbose to see the validation errors)',
        );
        if ( $self->verbose ) {
            for my $i ( 0..$#{ $reason } ) {
                $logger->warn( sprintf '%s error #%s: %s', $meta_file, $i + 1, $reason->[$i] )
            }
        }
        return;
    }

    $logger->info( sprintf '%s exists and valid', $meta_file );

    return $rs;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Deploy::Validate::Meta - Workflow meta file validator

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

TBD

=head1 Methods

=head2 coord_directive

=head2 coord_directive_var

=head2 file

=head2 is_invalid_workflow_meta

=head2 maybe_decode

=head2 serializer

=head2 wf_directive

=head2 wf_directive_var

=head1 SEE ALSO

L<App::Oozie>.

=cut
