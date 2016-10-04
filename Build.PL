use Modern::Perl;
use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'OLED',
     dist_author => ['Olli-Antti Kivilahti <olli-antti.kivilahti@jns.fi>'],
     dist_abstract => 'Client-server for managing NHD US2066 microchip-drive OLED displays',

     build_requires => {
	    'Modern::Perl' => '1',
     },

     requires => {
        'Time::HiRes' => '1.9740',
        'Config::Simple' => '4.58',
        'IO::Socket::UNIX' => '1.25',
     },

    );

$build->create_build_script;
