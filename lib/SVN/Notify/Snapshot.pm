package SVN::Notify::Snapshot;
$SVN::Notify::Snapshot::VERSION = '0.02';

use strict;
use File::Spec;
use File::Path qw( mkpath );
use File::Temp qw( tempdir );
use File::Basename qw( dirname fileparse );
use SVN::Notify ();
@SVN::Notify::Snapshot::ISA = qw(SVN::Notify);

=head1 NAME

SVN::Notify::Snapshot - Take snapshots from Subversion activity

=head1 VERSION

This document describes version 0.02 of SVN::Notify::Snapshot,
released October 19, 2004.

=head1 SYNOPSIS

Use F<svnnotify> in F<post-commit>:

  svnnotify --repos-path "$1" --revision "$2" \
    --to "/tmp/snapshot-$2.tar.gz" --handler Snapshot \
    --handle-path pathname [options]

Note that the C<--handle-path> argument, which specifies the portion
of the repository to take snapshot from, is not optional.

By default, the base path inside the snapshot will be the basename of
the C<--to> argument, but you may override it with C<--snapshot-base>.

=cut

use constant SuffixMap => {
    '.tar'      => '_tar',
    '.tar.gz'   => '_tar_gzip',
    '.tgz'      => '_tar_gzip',
    '.tbz'      => '_tar_bzip2',
    '.tbz2'     => '_tar_bzip2',
    '.tar.bz2'  => '_tar_bzip2',
    '.zip'      => '_zip',
};

sub prepare {
    my $self = shift;
    $self->prepare_recipients;
}

sub execute {
    my ($self) = @_;
    my $to = $self->{to} or return;
    my $repos = $self->{repos_path} or return;
    my $path = $self->{handle_path} or die "Must specify handle_path";
    my $temp = tempdir( CLEANUP => 1 );

    my ($to_base, $to_path, $to_suffix) = fileparse($to, qr{\..*});
    my $method = $self->SuffixMap->{lc($to_suffix)} or die "Unknown suffix: $to_suffix";

    my $base = (
        defined($self->{snapshot_base})
            ? $self->{snapshot_base} : $to_base
    );

    my $from = File::Spec->catdir($temp, $base);
    mkpath([ dirname($from) ]) unless -d dirname($from);

    $self->_run(
        'svn', 'export',
        -r => $self->{revision},
        "file://$repos/$path" => $from,
    );

    $self->can($method)->($self, $temp, $from, $to);
}

sub _tar {
    my ($self, $temp, $from, $to, $mode) = @_;

    $mode ||= '-cf';
    $self->_run( 'tar', $mode, $to, -C => $temp, '.' ) ;
}

sub _tar_gzip {
    my $self = shift;
    $self->_tar(@_, '-czf');
}

sub _tar_bzip2 {
    my $self = shift;
    $self->_tar(@_, '-cjf');
}

sub _zip {
    my ($self, $temp, $from, $to, $mode) = @_;

    require Cwd;
    my $dir = Cwd::getcwd();
    chdir $temp;

    $self->_run( 'zip', -r => $to, '.' );
}

sub _run {
    my $self = shift;
    (system { $_[0] } @_) == 0 or die "Running [@_] failed with $?: $!";
}

1;

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 SEE ALSO

L<SVN::Notify>, L<SVN::Notify::Config>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
