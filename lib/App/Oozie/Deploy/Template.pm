package App::Oozie::Deploy::Template;

use 5.010;
use strict;
use warnings;
use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Types::Common qw( IsDir );

use Config::Properties;
use Data::Dumper ();
use File::Basename;
use File::Path qw(
    make_path
    remove_tree
);
use File::Spec;
use File::Temp qw( tempfile );
use Hash::Flatten ();
use IPC::Cmd ();
use Moo;
use MooX::Options;
use Ref::Util qw(
    is_ref
    is_arrayref
    is_hashref
);
use Template ();
use Text::Trim qw( trim  );
use Types::Standard qw(
    ArrayRef
    CodeRef
    HashRef
    InstanceOf
    Int
    Str
);
use XML::LibXML ();

use constant {
    DEFINE_VAR_TMPL => q{%s='%s'},
};

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Generic
    App::Oozie::Role::Meta
);

# Temporary while testing
has write_ownership_to_workflow_xml => (
    is  => 'rw',
    isa => Int,
    default => sub { 0 },
);

has internal_conf => (
    is       => 'rw',
    required => 1,
    isa      => HashRef,
);

has oozie_workflows_base => (
    is       => 'rw',
    required => 1,
);

has ttlib_base_dir => (
    is       => 'rw',
    isa      => IsDir,
    required => 1,
);

has ttlib_dynamic_base_dir_name => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has possible_readme_file_names => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    default => sub {
        [
            qw(
                README
                README.md
            )
        ],
    },
);

has coordinator_directive_var_cache => (
    is  => 'rwp',
    isa => ArrayRef,
);

has process_coord_directive_varname => (
    is      => 'rw',
    isa     => CodeRef,
    default => sub {
        sub {
            my $name = shift;
            return $name;
        },
    }
);

sub get_job_conf {
    my $self = shift;
    my $file = shift;
    my %job_conf;
    # Defined the variables in job.properties for all files processed in
    # the workflow directory.
    # Note that this is only useful for constants like maximum values
    # and anything referencing Oozie vars or functions is useless
    # as the will be the non-expanded raw values, since this is Perl not Oozie.
    # doing the expansion.
    #
    my $p = Config::Properties->new();
    my $FH;
    open $FH, '<', $file or die "Cannot open $file";
    $p->load($FH);
    my %c = $p->properties;
    for my $key ( keys %c ) {
        my $val = $c{ $key };
        if ( is_ref $val ) {
            $self->logger->logdie(
                sprintf 'You seem to have a double definition in %s for %s as %s',
                            $file,
                            $key,
                            do { my $d = Data::Dumper->new([ $val ], [ $key ]); $d->Dump },
            );
        }
        $val =~ s{ [^\\][#] .* \z }{}xms;
        $job_conf{ "JOBCONF_" . $key } = trim $val;
    }

    return %job_conf;
}

sub compile {
    my $self     = shift;
    my $workflow = shift;

    my $config   = $self->internal_conf;
    my $dryrun   = $self->dryrun;
    my $logger   = $self->logger;
    my $verbose  = $self->verbose;
    my $appname  = basename $workflow;
    my $dest     = File::Spec->catfile(
                        $config->{base_dest},
                        substr($workflow, 1 + length $self->oozie_workflows_base),
                    );

    my $deploy_temp_lib_dir = File::Spec->catfile( $dest, $self->ttlib_dynamic_base_dir_name );

    $logger->info(
        sprintf "Processing `%s` with the application name `%s` into `%s`",
                    $workflow,
                    $appname,
                    $dest,
    );

    # [dmorel 2014-01-30] -> Verify if this is still the case.
    # work around a bug in TT2 (our version, didn't check others); When
    # processing a template, the destination directory will be created, but not
    # when copying a file. So when the copied file is first in the list, TT
    # will choke on 'No such file or directory'
    #

    make_path   $dest,
                ( $self->write_ownership_to_workflow_xml ? ( $deploy_temp_lib_dir ) : () ), # we can just use this as the base is $dest but keep hem separate just in case
                {
                    mask => oct(755),
                };

    my $tt_conf_file = $self->_pre_process_ttconfig_into_tempfile({
                            ( $self->write_ownership_to_workflow_xml ? (
                                temp_lib => $deploy_temp_lib_dir,
                            ) : () ),
                        });

    # Possible improvement: use libraries instead of this command
    #     if feasible
    my @command = (
        'ttree',
        '-f'     => $tt_conf_file,
        '-a',
        '--src'  => $workflow,
        '--dest' => $dest,
        '--verbose',
    );

    for my $prop ( keys %$config ) {
        if ( !defined $config->{$prop} ) {
            $logger->warn( "Conf error: $prop has no value defined!" )
                if $prop ne
                "has_sla";    # dmorel 2015-03-09: skip the error for the sla key (change later?)
            next;
        }
        push @command,
            '--define' => sprintf( DEFINE_VAR_TMPL, $prop, $config->{$prop} );
    }
    my($validation_errors, $total_errors);
    my $job_properties_file = File::Spec->catfile( $workflow, 'job.properties' );

    if ( -e $job_properties_file ) {
        my %job_conf = $self->get_job_conf( $job_properties_file );
        foreach my $name ( keys %job_conf ) {
            push @command,
                '--define' => sprintf( DEFINE_VAR_TMPL, $name, $job_conf{ $name } );
        }

    }

    my $meta_file = File::Spec->catfile( $workflow, $self->meta->file );

    if ( -e $meta_file ) {
        my @rs = $self->_create_meta_includes({
                        source_dir  => $workflow,
                        source_file => $meta_file,
                        dest_dir    => $deploy_temp_lib_dir,
                    });
        for my $tuple ( @rs ) {
            my( $key, $value) = @{ $tuple };
            push @command,
                '--define' => sprintf( DEFINE_VAR_TMPL, $key, $value );
        }
    }

    my( $ok, $err, $full_buf, $stdout_buff, $stderr_buff ) = IPC::Cmd::run(
        command => \@command,
        verbose => $self->verbose,
        timeout => $self->timeout,
    );

    # ttree doesn't return an error status when it encounters an error, so just
    # look at the output
    # typical error output: '  ! file error - parse error - file.tt line 314: unexpected end of input'
    # Template::Exception stringifies to "$type error - $info", and ttree prefixes errors with '  ! '
    if ( $ok ) {
        $ok = ! grep {
                    m{^ (?:\s+)? ! .+? \berror\b \s+ [-] \s+ }xms
                } @{ $full_buf };
    }

    $total_errors += !$ok;

    if ( $ok ) {
        $logger->info('Template Toolkit compilation status: OK');
    }
    else {
        $logger->error(
                'Template Toolkit  status: FAILED - complete output: ',
                join( "\n", @{ $full_buf } )
        );
    }

    $self->_probe_readme(
        $workflow,
        \$validation_errors,
        \$total_errors,
    );

    if ( $self->write_ownership_to_workflow_xml ) {
        if ( ! $dryrun ) {
            $logger->debug(
                sprintf 'Removing the dynamic include dir: %s',
                            $deploy_temp_lib_dir,
            ) if $verbose;
            remove_tree $deploy_temp_lib_dir;
        }
        else {
            $logger->debug(
                sprintf 'Keeping the dynamic include dir: %s',
                            $deploy_temp_lib_dir,
            ) if $verbose;
        }
    }

    return  $validation_errors // 0,
            $total_errors      // 0,
            $dest,
    ;
}

sub _probe_readme {
    my $self                  = shift;
    my $workflow              = shift;
    my $validation_errors_ref = shift;
    my $total_errors_ref      = shift;

    my $logger = $self->logger;
    my $has_readme;
    for my $possible_file ( @{ $self->possible_readme_file_names } ) {
        my $path = File::Spec->rel2abs(
                        File::Spec->catfile(
                            $workflow,
                            $possible_file,
                        )
                    );
        if ( -f $path ) {
            $has_readme = $possible_file;
            last;
        }
    }

    if ( ! $has_readme ) {
        $logger->error(
            "A README file is missing in workflow folder $workflow. ",
            "This file must be present and it must contain a short explanation of what the workflow is for. ",
            sprintf( "Please add a file named %s and try redeploying the workflow.",
                        join( q{ or }, @{ $self->possible_readme_file_names } ),
            ),
        );
        ${ $validation_errors_ref }++;
        ${ $total_errors_ref }++;
    }
    else {
        $logger->debug( sprintf 'Has a %s', $has_readme )
            if $self->verbose;
    }

    return;
}

sub _create_meta_includes {
    my $self   = shift;
    my $opt    = shift;
    my $logger = $self->logger;

    if ( ! $self->write_ownership_to_workflow_xml ) {
        if ( $self->verbose ) {
            $logger->debug('write_ownership_to_workflow_xml is false. Skipping ...');
        }
        return;
    }

    die "Options need to be a hashref!" if ! $opt || ! is_hashref $opt;

    my $source_dir = $opt->{source_dir};
    my $meta_file  = $opt->{source_file};
    my $dest_dir   = $opt->{dest_dir};

    if ( ! -d $source_dir ) {
        die "source_dir=$source_dir is not a directory!";
    }

    if ( ! -d $dest_dir ) {
        die "dest_dir=$dest_dir is not a directory!";
    }

    $logger->info(
        sprintf '%s exists and the data in there will be populated into workflow.xml',
                    $meta_file,
    );

    my $rs = $self->meta->maybe_decode( $meta_file ) || return;

    my @define;

    if ( $self->_create_wf_directive( $dest_dir, $rs ) ) {
        push @define,
                [
                    $self->meta->wf_directive_var,
                    $self->meta->wf_directive,
                ];
    }

    return @define;
}

sub _xml_escape {
    my($self, $input) = @_;
    return XML::LibXML::Document
            ->new('1.0', 'UTF-8')
            ->createTextNode( $input )
            ->toString;
}

sub _freeze_ttvar {
    my $self       = shift;
    my $tt_varname = shift;
    my $var        = shift;

    my $d   = Data::Dumper->new( [ $var ], [ $tt_varname ] );
    my $lin = $d->Dump;
    $lin =~ s{ \A [\$] }{}xms;
    return $lin;
}

sub _create_wf_directive {
    my $self        = shift;
    my $dest_dir    = shift;
    my $rs          = shift;
    my $tt_varname  = 'oozie_lineage';
    my $key_prefix  = 'bigdatameta';
    my $tt_variable = do {
        my %tot =   map  { $_ => scalar @{ $rs->{lineage}{ $_ } } }
                    grep { is_arrayref $rs->{lineage}{ $_ } }
                    keys %{ $rs->{lineage} };
        for my $name ( keys %tot ) {
            $rs->{total}{ $name } = $tot{ $name };
        }

        my $flat = Hash::Flatten->new->flatten( $rs );
        my $var  = [
            map {
                +{
                    key   => $key_prefix . '.' . $_,
                    value => $self->_xml_escape( $flat->{ $_ } ),
                }
            }
            sort { lc $a cmp lc $b }
            keys %{ $flat }
        ];
        $self->_freeze_ttvar( $tt_varname => $var );
    };

    my $var_file = File::Spec->catfile( $dest_dir, $self->meta->wf_directive );

    return $self->_create_directive_file( $var_file, $tt_variable, $tt_varname );
}

sub _create_directive_file {
    my $self = shift;
    my($var_file, $tt_variable, $tt_varname) = @_;

    my $tmpl = <<'TMPL';
[% {% tt_variable %} %]
[% FOREACH entry IN {% tt_varname %}  %]
        <property>
            <name>[%  entry.key   %]</name>
            <value>[% entry.value %]</value>
        </property>
[% END %]
TMPL

    my $tt = Template->new(
        START_TAG => '{%',
        END_TAG   => '%}',
    );

    $tt->process(
        \$tmpl,
        {
            tt_variable => $tt_variable,
            tt_varname  => $tt_varname,
        },
        \my $buf,
    );

    open my $FH, '>', $var_file or die "Can't write to $var_file: $!";
    print $FH "$buf\n";
    close $FH;

    $self->logger->debug( sprintf 'meta file created as: %s', $var_file )
        if $self->verbose;

    return $var_file;
}

sub _pre_process_ttconfig_into_tempfile {
    my $self   = shift;
    my $opt    = shift || {};
    my $logger = $self->logger;

    my($fh_tmp_cfg, $tmp_cfg_file) = tempfile();

    my $file = File::Spec->catfile( $self->ttlib_base_dir, 'ttree.cfg' );
    open my $FH, '<', $file or die "Failed to read $file: $!";

    while ( <$FH> ) {
        if ( /^copy/ ) {
            $logger->info(
                sprintf "Files matching this pattern will be copied as-is: /%s/",
                            trim +(split m{ [=] }xms, $_, 2)[-1]
            );
        }

        print $fh_tmp_cfg $_;
    }

    # Attach the correct lib dir to the conf
    printf $fh_tmp_cfg "\nlib = %s\n", $self->ttlib_base_dir;

    # custom includes
    if ( $opt->{temp_lib} && -d $opt->{temp_lib} && -r _ ) {
        printf $fh_tmp_cfg "\nlib = %s\n", $opt->{temp_lib};
    }

    close $FH;

    $logger->debug( sprintf 'TT conf file created as %s', $tmp_cfg_file )
        if $self->verbose;

    return $tmp_cfg_file;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Deploy::Template - Template Toolkit compiler for Oozie workflow specs.

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

TBD

=head1 Methods

=head2 compile

=head2 coordinator_directive_var_cache

=head2 get_job_conf

=head2 oozie_workflows_base

=head2 possible_readme_file_names

=head1 Constants

=head2 DEFINE_VAR_TMPL

=head1 SEE ALSO

L<App::Oozie>.

=cut
