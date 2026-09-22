#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Physics::PVD::DSMC;

print "Argon transport regimes for a 4 cm target-substrate gap\n";
printf "%10s %14s %12s  %s\n", 'P (Pa)', 'lambda (m)', 'Kn', 'regime';

for my $pressure (0, 0.01, 0.1, 1, 10, 100) {
    my $dsmc = Physics::PVD::DSMC->new(
        pressure           => $pressure,
        temperature        => 300,
        sigma_ref          => 3.0e-19,
        substrate_distance => 0.04,
    );
    printf "%10.2g %14.4g %12.4g  %s\n",
        $pressure,
        $dsmc->mean_free_path,
        $dsmc->knudsen_number,
        $dsmc->transport_regime;
}
