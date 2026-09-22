use strict;
use warnings;
use Test::More;
use Physics::PVD::DSMC;

my $dsmc = Physics::PVD::DSMC->new(
    pressure             => 2.0,
    temperature          => 300,
    sigma_ref            => 3.0e-19,
    substrate_distance   => 0.04,
    n_particles          => 1,
    seed                 => 17,
);

my $expected_mfp = Physics::PVD::DSMC::KB() * 300
    / (sqrt(2) * 2.0 * 3.0e-19);
my $relative_error = abs($dsmc->mean_free_path - $expected_mfp) / $expected_mfp;
cmp_ok($relative_error, '<', 1e-12, 'mean free path uses hard-sphere formula');

my $expected_kn = $expected_mfp / 0.04;
$relative_error = abs($dsmc->knudsen_number - $expected_kn) / $expected_kn;
cmp_ok($relative_error, '<', 1e-12, 'Knudsen number uses substrate distance');

is($dsmc->transport_regime(0),     'continuum',      'zero Kn is continuum');
is($dsmc->transport_regime(0.01),  'slip',           'slip lower boundary');
is($dsmc->transport_regime(0.1),   'transitional',   'transition lower boundary');
is($dsmc->transport_regime(10),    'free_molecular', 'free-molecular boundary');
is($dsmc->transport_regime, 'transitional', 'current chamber is classified');

my $stats = $dsmc->stats;
ok(exists $stats->{knudsen_number}, 'legacy Knudsen statistic remains present');
is($stats->{transport_regime}, 'transitional', 'stats includes regime');
cmp_ok($stats->{mean_free_path_m}, '>', 0, 'stats includes mean free path');

my $vacuum = Physics::PVD::DSMC->new(pressure => 0);
cmp_ok($vacuum->mean_free_path, '>', 1e300, 'vacuum has infinite mean free path');
is($vacuum->transport_regime, 'free_molecular', 'vacuum is free molecular');

for my $case (
    [ { pressure => -1 }, qr/gas pressure/, 'negative pressure rejected' ],
    [ { temperature => 0 }, qr/gas temperature/, 'zero temperature rejected' ],
    [ { sigma_ref => 0 }, qr/sigma_ref/, 'zero cross-section rejected' ],
    [ { substrate_distance => 0 }, qr/substrate distance/, 'zero distance rejected' ],
) {
    my ($opts, $error, $name) = @$case;
    my $bad = Physics::PVD::DSMC->new(%$opts);
    my $ok = eval { $bad->knudsen_number; 1 };
    ok(!$ok, $name);
    like($@, $error, "$name has a useful message");
}

my $ok = eval { $dsmc->transport_regime(-0.1); 1 };
ok(!$ok, 'negative explicit Knudsen number rejected');
like($@, qr/Knudsen number/, 'invalid Knudsen number has a useful message');

done_testing;
