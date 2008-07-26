use lib './lib';
use strict;
use warnings;
use Test::More tests => 4;
use Image::Magick;
use Image::Magick::Text::AutoBreak;
use Encode qw(decode);
use encoding 'utf8';

my $image = Image::Magick->new;
$image->Read('./t/source/test.jpg');

### ----------------------------------------------------------------------------
### 1. Constract
### ----------------------------------------------------------------------------
my $autobreak =
    Image::Magick::Text::AutoBreak->new(
        magick          => $image,
        width           => 340,
        x               => 10,
        y               => 80,
        ngCharaForHead => qr/[\\Q,)]｝、〕〉》」』】〟’”`≫。.・:;ヽヾーァィゥェォッャュョヮヵヶぁぃぅぇぉっゃゅょゎ\\E]/, 
        ngCharaForTail => qr/[\\Q([｛〔〈《「『【〝‘“_≪\\E]/, 
        ngCharaForSepa => qr/[\\Qa-zA-Z0-9'".,!?-\\E]/, 
    );

is( ref $autobreak, 'Image::Magick::Text::AutoBreak' );

### ----------------------------------------------------------------------------
### 2. Define syntax
### ----------------------------------------------------------------------------
my $str = <<EOF;
This is a utility class for Image::Magick. With this module, you can easily annotate long strings into multiple lines. This also provides you a simple line boundary character check mechanism.

This is a utility class for Image::Magick.

With this module
EOF

my @result = $autobreak->prepare(
    text            => $str, 
    font            => './t/font/FreeMonoBoldOblique.ttf', 
    pointsize       => 14,
    fill            => '#000000',
);

is( int($result[0]), 336 );

### ----------------------------------------------------------------------------
### 3. Define syntax
### ----------------------------------------------------------------------------
is( int($result[1]), 246 );

### ----------------------------------------------------------------------------
### 4. Define syntax
### ----------------------------------------------------------------------------
my @result2 = $autobreak->annotate(
    fill            => '#ffffff',
    stroke          => '#ffffff',
    strokewidth     => 6,
);
$autobreak->annotate();

is(scalar @result2, 2);
