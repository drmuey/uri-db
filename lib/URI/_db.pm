package URI::_db;

use strict;
use 5.8.1;
use base 'URI::_login';
our $VERSION = '0.10';

sub engine { shift->scheme(@_) }
sub uri    { shift }

sub has_recognized_engine {
    ref $_[0] ne __PACKAGE__;
}

sub dbname {
    my $self = shift;
    my $is_full = $self->opaque =~ m{^//(?://|(?!/))};
    return $self->path($is_full && defined $_[0] ? "/$_[0]" : shift) if @_;
    my @segs = $self->path_segments or return;
    shift @segs if $is_full;
    join '/' => @segs;
}

sub query_params {
    my $self = shift;
    require URI::QueryParam;
    return map {
        my $f = $_;
        map { $f => $_ } grep { defined } $self->query_param($f)
    } $self->query_param;
}

sub _dbi_param_map {
    my $self = shift;
    return (
        [ host   => scalar $self->host    ],
        [ port   => scalar $self->_port   ],
        [ dbname => scalar $self->dbname ],
    );
}

sub dbi_params {
    my $self = shift;
    return (
        (
            map { @{ $_ } }
            grep { defined $_->[1] && length $_->[1] } $self->_dbi_param_map
        ),
        $self->query_params,
    );
}

sub dbi_driver { return undef }

sub _dsn_params {
    my $self = shift;
    my @params = $self->dbi_params;
    my @kvpairs;
    while (@params) {
        push @kvpairs => join '=', shift @params, shift @params;
    }
    return join ';' => @kvpairs;
}

sub dbi_dsn {
    my $self = shift;
    my $driver = $self->dbi_driver or return $self->_dsn_params;
    return join ':' => 'dbi', $driver, $self->_dsn_params;
}

1;
