use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Image::Magick::Text::AutoBreak',
    license             => 'perl',
    dist_author         => 'Sugama Keita <sugama@jamadam.com>',
    dist_version_from   => 'lib/Image/Magick/Text/AutoBreak.pm',
    requires => {
        'Test::More' 	=> 0,
        'Image::Magick' => 0,
        'Encode'		=> 0,
    },
    add_to_cleanup      => [ 'Image-Magick-Text-AutoBreak-*' ],
);

$builder->create_build_script();
