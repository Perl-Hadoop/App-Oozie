package App::Oozie::Util::Plugin;

use 5.014;
use strict;
use warnings;
use parent qw( Exporter );

use File::Spec::Functions qw(
    catdir
    catfile
    splitdir
);

our @EXPORT_OK = qw(
    find_files_in_inc
    find_plugins
    load_plugin
);

sub find_plugins {
    my $base_class = shift || die "Please specify a base class name";
    my $fext       = shift || 'pm';

    (my $base_path = $base_class) =~ s{::}{/}xmsg;

    my @found = find_files_in_inc( $base_path, $fext );
    my %action_to_class = map {
        lc( $_->{name} ) => $base_class . '::' . $_->{name}
    } @found;

    return \%action_to_class;
}

sub find_files_in_inc {
    my $base_path = shift || die "base_path not specified";
    my $fext      = shift || die "File exrentension not specified";

    my $re_file_extension = qr{
        [.] $fext
        \z
    }xms;

    my(@found, %seen_path);
    for my $path ( @INC ) {
        my $test = catdir $path, $base_path;
        next if ! -d $test || ! -e _;
        opendir my $DIR, $test or die "Can't opendir $test: $!";
        my @wanted;
        while ( my $file = readdir $DIR ) {
            my $fp = catfile $test, $file;
            next if    $seen_path{ $fp }++
                    || $fp =~ m{ \A [.]+ \z }xms
                    || ! -f $fp
                    || $fp !~ $re_file_extension
            ;
            (my $name = $file) =~ s{ $re_file_extension }{}xms;
            push @found,
                {
                    abs_path => $fp,
                    file     => $file,
                    name     => $name,
                };
        }
    }

    return @found;
}

sub load_plugin {
    my $class = shift || die "No class specified for loading";
    eval qq{
        require $class;
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        die sprintf 'Error loading %s: %s', $class, $eval_error;
    };
    return $class;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Util::Plugin; - Utility for polugin handling.

=head1 SYNOPSIS

    use App::Oozie::Util::Plugin qw(
        find_files_in_inc
        find_plugins
        load_plugin
    );

=head1 DESCRIPTION

Internal utility.

=head1 Methods

=head2 find_files_in_inc

=head2 find_plugins

=head2 load_plugin

=head1 SEE ALSO

L<App::Oozie>.

=cut
