package Image::Magick::Text::AutoBreak;
use warnings;
use strict;
use Carp;
use Image::Magick;
use Encode qw(decode);
our $VERSION = '0.02';

###  ---------------------------------------------------------------------------
### Constractor
###  ---------------------------------------------------------------------------
sub new {
    
    my $class = shift;
    my $self = 
        bless {
            magick 				=> undef, 
            charset 			=> 'utf8', 
            ngCharaForHead 		=> undef,
            ngCharaForTail 		=> undef, 
            ngCharaForSepa		=> undef,
            x               	=> 0,
            y               	=> 0,
            width           	=> undef,
            height          	=> undef,
            'line-spacing'  	=> 4,
            _plan           	=> [],      
            _result 			=> undef,
            @_}, $class;
    
	if (! $self->{width}) {
		
		$self->{width} = $self->{magick}->Get('width') - $self->{x};
	}
    
	if (! $self->{height}) {
		
		$self->{height} = $self->{magick}->Get('height') - $self->{y};
	}
    
    return $self;
}

###  ---------------------------------------------------------------------------
### Prepare the plan for annotation
### This calls for same params as Image::Magick->Annotate
###  ---------------------------------------------------------------------------
sub prepare {
    
    my $self = shift;
    my %args = (
        text            => '',
        fill            => '#000000',
        pointsize       => 9,
        @_);
    
    $self->{_result} = {width => 0, height => 0};
    
    my $in_str = 
        utf8::is_utf8($args{text}) 
            ? $args{text}
            : decode($self->{charset}, $args{text});
    
    my $y_pos = $self->{y};
    
    foreach my $line (split(/\r\n|\n|\r/, $args{text})) {
        
        if ($y_pos > $self->{y} + $self->{height}) {
            
            last;
        }
        
        if (! $line) {
            
            $y_pos += $args{pointsize} + $self->{'line-spacing'};
            next;
        }
        
        $y_pos = 
            $self->_makePlan(
                %args,
                text    => $line,
                x       => $self->{x},
                y       => $y_pos + $self->{'line-spacing'}
            );
    }
    
    if ($y_pos > $self->{_result}->{height}) {
        
        $self->{_result}->{height} = $y_pos;
    }
    
    return $self->getResult();
}

###  ---------------------------------------------------------------------------
### make plan for annotation
### @return int height
###  ---------------------------------------------------------------------------
sub _makePlan {
    
    my $self = shift;
    my %args = (@_);
    
    $args{text} =~ s/^\s//;
    
    my @box;
	
	### set initial position to last length
    my $pos1 = ($args{_last_length} or 1);
	
	@box = 
        $self->{magick}->QueryFontMetrics(
			%args, text => substr($args{text}, 0, $pos1)
		);
    
	### Set destination of search for horizontal limit
    my $increment = ($box[4] > $self->{width}) ? -1 : 1;
    
    ### Search for horizontal limit
    for (my $i = $pos1;
         $i > 0 and $i <= length($args{text});
         $i += $increment) {
        
        @box =
            $self->{magick}->QueryFontMetrics(
                %args,
                text => substr($args{text}, 0, $i),
            );
        
        if ($increment == 1 and $box[4] > $self->{width}) {
            
            last;
        }
        
        $pos1 = $i;
        
        if ($increment == -1 and $box[4] < $self->{width}) {
            
            last;
        }
    }
    
    if ($args{y} + $box[5] > $self->{y} + $self->{height}) {
        
        return $args{y};
    }
    
    ### word wrapping
    if ($pos1 < length($args{text})) {
        
        while ($pos1 > 1) {
            
            my $next = substr($args{text}, $pos1, 1);
            
            if ($next and $next =~ $self->{ngCharaForHead}) {
                
                $pos1--; next;
            } 
            
            my $last = substr($args{text}, $pos1 - 1, 1);
            
            if ($last and $last =~ $self->{ngCharaForTail}) {
                
                $pos1--; next;
            }
            
            if ($last =~ $self->{'ngCharaForSepa'} and 
                $next =~ $self->{'ngCharaForSepa'}) {
                
                $pos1--; next;
            }
            
            last;
        }
        
        @box =
            $self->{magick}->QueryFontMetrics(
                %args,
                text => substr($args{text}, 0, $pos1)
            );
    }
    
    ### Record result
    if ($box[4] > $self->{_result}->{width}) {
        
        $self->{_result}->{width} = $box[4];
    }

    $args{_last_length} = $pos1;
    
    push(@{$self->{_plan}},
        {
            %args,
            text    => substr($args{text}, 0, $pos1),
            y       => $args{y} + $box[5]
        }
    );
    
    ### Evaluate tail str
    if ($pos1 < length($args{text})) {
        
        return 
            $self->_makePlan(
                %args, 
                y       => $args{y} + $box[5] + $self->{'line-spacing'}, 
                text    => substr($args{text}, $pos1)
            );
    }
    
    ### Returns bottom position of written box
    return $args{y} + $args{pointsize};
}

### ----------------------------------------------------------------------------
### annotate
### This calls for same params as Image::Magick->Annotate
### ----------------------------------------------------------------------------
sub annotate {
	
    my $self = shift;
    my %args = (@_);
	
	for my $default_args (@{$self->{_plan}}) {
		
	    $self->{magick}->Annotate(%$default_args, %args);
	}
	
    return $self->getResult();
}
### ----------------------------------------------------------------------------
### get result
### @return int width or height
### ----------------------------------------------------------------------------
sub getResult {
    
    my $self = shift;
    
    if ($_[0]) {
        
        return $self->{_result}->{$_[0]};
    }
    
    return ($self->{_result}->{width}, $self->{_result}->{height});
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Image::Magick::Text::AutoBreak - Utility for auto line break

=head1 VERSION

This document describes Image::Magick::Text::AutoBreak version 0.02

=head1 DESCRIPTION

This is a utility class for Image::Magick. With this module, you can easily
annotate long strings into multiple lines. 

=head1 SYNOPSIS

    use Image::Magick::Text::AutoBreak;
    
    ### Prepare source
    my $image = Image::Magick->new;
    $image->Read($filename);
    
    ### Constractor
    my $autobreak =
        Image::Magick::Text::AutoBreak->new(
            magick          => $image,
            width           => 231,
            height          => 260,
            x               => 10,
            y               => 80,
            ngCharaForHead => qr/[\\Q,)]`.:;\\E]/, 
            ngCharaForTail => qr/[\\Q([_\\E]/, 
            ngCharaForSepa => qr/[\\Qa-zA-Z0-9'".,!?-\\E]/, 
        );
    
    ### Prepare for annotate before hand
    my @result = $autobreak->prepare(
        text            => $input_string, 
        font            => $font_path, 
        pointsize       => 9,
        fill            => '#000000',
    );
    
    ### Annotate
    $autobreak->annotate();
    
    ### Repeatedly if you need
    $autobreak->annotate(fill => '#0000ff');

=head1 INTERFACE 

=head2 new

Constractor. This calls for folloing arguments.

=over 4

B<magick>

Image::Magick instance.

B<x>

Horizontal position of text area.

B<y>

Vertical position of text area.

B<width>

Width of text area. If not given, allocates [I<source image width>] - x

B<height>

Height of text area. If not given, allocates [I<source image height>] - y

B<ngCharaForHead>

Denied charactors for line head in regular expression 

B<ngCharaForTail>

Denied charactors for end-of-line in regular expression 

B<ngCharaForSepa>

Denied charactors for separation in regular expression 

=back

=head2 prepare

This method prepare the annotaion plan. This calls for same arguments as the
I<Image::Magick::QueryFontMetrics> does, and the arguments will be thrown at
it. 

    my @result = $autobreak->prepare(
        text            => $input_string, 
        font            => $font, 
        fill            => '#000000',
        pointsize       => 12,
    );

The arguments will be adopted for default args of I<annotate> thereafter.
This method returns the box size of annotation area in array.

=head2 annotate

This method is a wrapper for I<Image::Magick::Annotate>. This does I<Annotate>
iteratively so that the input strings will be put into multiple line. 

This method automatically takes the arguments that I<prepare> has gotten, and
you can override each of them.

    $autobreak->annotate(fill => '#ffffff');

The arguments will be thrown at I<Image::Magick::Annotate>. Practically, you
should give the arguments that doesn't have influence on the position or size
of each line.
    
    # This doesn't make sense
    $autobreak->annotate(pointsize   => 14);

You can do I<annotate> repeatedly if you need to decorate or something.

    # Draw stroke
    $autobreak->annotate(
        fill            => '#ffffff',
        stroke          => '#ffffff',
        strokewidth     => 6,
    );

    # real part
    $autobreak->annotate();

This method returns the box size of prepared annotation area in array. 

=head2 getResult

This method returns the box size of prepared annotation area in array.

=head1 CONFIGURATION AND ENVIRONMENT

Image::Magick::Text::AutoBreak requires no configuration files or
environment variables. 

=head1 DEPENDENCIES

=over

=item L<encoding>

=item L<Image::Magick>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-syntax-highlight-engine-Simple@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.

=head1 SEE ALSO

=over

=item L<Image::Magick>

=back

=head1 AUTHOR

Sugama Keita  C<< <sugama@jamadam.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Sugama Keita C<< <sugama@jamadam.com> >>. All rights
reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See I<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
