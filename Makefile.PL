use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Image::Magick::Text::AutoBreak',
    AUTHOR              => 'Sugama Keita <sugama@jamadam.com>',
    VERSION_FROM        => 'lib/Image/Magick/Text/AutoBreak.pm',
    ABSTRACT_FROM       => 'lib/Image/Magick/Text/AutoBreak.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' 	=> 0,
        'Image::Magick' => 0,
        'Encode'		=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Image-Magick-Text-AutoBreak-*' },
);
