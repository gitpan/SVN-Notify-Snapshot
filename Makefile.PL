#!/usr/bin/env perl

use inc::Module::Install;

name		('SVN-Notify-Snapshot');
author		('Autrijus Tang <autrijus@autrijus.org>');
abstract	('Make snapshots from Subversion activities');
license		('perl');
version_from	('lib/SVN/Notify/Snapshot.pm');

requires	(
    'SVN::Notify'   => 2.22,
);

WriteAll( sign => 1 );
