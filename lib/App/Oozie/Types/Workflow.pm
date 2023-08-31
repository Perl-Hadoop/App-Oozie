package App::Oozie::Types::Workflow;

use 5.010;
use strict;
use warnings;

use Email::Valid;
use Sub::Quote qw( quote_sub );
use Type::Library -base;
use Type::Tiny;
use Type::Utils -all;

BEGIN {
    extends 'Types::Standard';
}

use constant {
    RE_LINEAGE_DATA_ITEM => qr{
        \A
            hive     # Data source type
            [/]      # Separator
            [\w^.]+  # Database name
            [.]      # Separator
            [\w^.]+  # Table name
        \z
    }xms,
};

my $Email = declare Email => as Str,
    constraint => quote_sub q{
        my $input = shift;
        $input && Email::Valid->address( $input );
    },
;

my $LineageDataItem = declare LineageDataItem => as Str,
    constraint => quote_sub(
        q{
            my $input = shift;
            $input && $input =~ $pattern
        },
        {
            '$pattern' => RE_LINEAGE_DATA_ITEM,
        },
    ),
;

my $Justification = declare Justification => as Str,
    constraint => quote_sub(
        q{
            my $input = shift;
            if ( ! $input ) {
                return;
            }
            $input =~ s{ \A \s+}{}xms;
            $input =~ s{ \s+ \z }{}xms;
            my $len = length $input; # Do nothing as this is marked optional
            if ( $len < $min_length ) {
                warn sprintf "Justification defined with %s characters while at least %s characters are needed",
                                 $len,
                                 $min_length,
                ;
                return;
            }
            # looks alright
            return 1;
        },
        {
           '$min_length' => \200,
        },
    ),
;

my $WorkflowMeta = declare WorkflowMeta => as Dict[
    lineage => Maybe[ Optional[
        Dict[
            inputs  => Optional[ ArrayRef[ $LineageDataItem ] ],
            outputs => Optional[ ArrayRef[ $LineageDataItem ] ],
        ]
    ]],
    ownership => Dict[
        emails        => Optional[ ArrayRef[ $Email ] ],
        justification => Optional[ $Justification ],
        org_id        => Optional[ Str ],
        team          => Optional[ Str ],
    ],
];

my $DummyWorkflowMeta = declare DummyWorkflowMeta => as Dict[
    lineage => Maybe[ Dict[
        inputs  => Optional[ ArrayRef[ Str ] ],
        outputs => Optional[ ArrayRef[ Str ] ],
    ]],
    ownership => Dict[
        emails        => Optional[ ArrayRef[ Str ] ],
        justification => Optional[ Str ],
        org_id        => Optional[ Str ],
        team          => Optional[ Str ],
    ],
];

union WorkflowMetaOrDummy => [ $WorkflowMeta, $DummyWorkflowMeta ];

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Types::Workflow - Internal types.

=head1 SYNOPSIS

    use App::Oozie::Types::Workflow qw( WorkflowMeta );

=head1 DESCRIPTION

Internal types.

=head1 Types

=head2 DummyWorkflowMeta

=head2 Email

=head2 Justification

=head2 LineageDataItem

=head2 WorkflowMeta

=head1 SEE ALSO

L<App::Oozie>.

=cut
