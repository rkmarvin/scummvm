#!/usr/bin/perl
#
# This tools is kind of a hack to be able to maintain the credits list of
# ScummVM in a single central location. We then generate the various versions
# of the credits in other places from this source. In particular:
# - The AUTHORS file
# - The gui/credits.h header file
# - The credits.xml file, part of the DocBook manual
# - Finally, credits.inc, from the website
# And maybe in the future, also "doc/10.tex", the LaTeX version of the README.
# Although that might soon be obsolete, if the manual evolves enough.
#
# Initial version written by Fingolfin in December 2004.
#


use strict;
use Text::Wrap;

if ($Text::Wrap::VERSION < 2001.0929) {
	die "Text::Wrap version >= 2001.0929 is required. You have $Text::Wrap::VERSION\n";
}

my $mode = "";
my $max_name_width;

# Count the level in the section hierarchy, i.e. how deep we are currently nested
# in terms of 'sections'.
my $section_level = 0;

# Count how many sections there have been on this level already
my @section_count = ( 0, 0, 0 );

if ($#ARGV >= 0) {
	$mode = "TEXT" if ($ARGV[0] eq "--text");	# AUTHORS file
	$mode = "HTML" if ($ARGV[0] eq "--html");	# credits.inc (for use on the website)
	$mode = "CPP" if ($ARGV[0] eq "--cpp");		# credits.h (for use by about.cpp)
	$mode = "XML" if ($ARGV[0] eq "--xml");		# credits.xml (DocBook)
	$mode = "RTF" if ($ARGV[0] eq "--rtf");		# Credits.rtf (Mac OS X About box)
	$mode = "TEX" if ($ARGV[0] eq "--tex");		# 10.tex (LaTeX)
}

if ($mode eq "") {
	print STDERR "Usage: $0 [--text | --html | --cpp | --xml | --rtf]\n";
	print STDERR " Just pass --text / --html / --cpp / --xml / --rtf as parameter, and credits.pl\n";
	print STDERR " will print out the corresponding version of the credits to stdout.\n";
	exit 1;
}

$Text::Wrap::unexpand = 0;
if ($mode eq "TEXT") {
	$Text::Wrap::columns = 78;
	$max_name_width = 21; # The maximal width of a name.
} elsif ($mode eq "CPP") {
	$Text::Wrap::columns = 48;	# Approx.
}

# Convert HTML entities to ASCII for the plain text mode
sub html_entities_to_ascii {
	my $text = shift;
	
	# For now we hardcode these mappings
	# &aacute;  -> a
	# &eacute;  -> e
	# &oacute;  -> o
	# &oslash;  -> o
	# &ouml;    -> o / oe
	# &auml;    -> a
	# &amp;     -> &
	# &#322;    -> l
	$text =~ s/&aacute;/a/g;
	$text =~ s/&eacute;/e/g;
	$text =~ s/&oacute;/o/g;
	$text =~ s/&oslash;/o/g;
	$text =~ s/&#322;/l/g;

	$text =~ s/&auml;/a/g;
	$text =~ s/&uuml;/u/g;
	# HACK: Torbj*o*rn but G*oe*ffringmann and R*oe*ver
	$text =~ s/&ouml;r/or/g;
	$text =~ s/&ouml;/oe/g;

	$text =~ s/&amp;/&/g;
	
	return $text;
}

# Convert HTML entities to RTF codes
sub html_entities_to_rtf {
	my $text = shift;
	
	$text =~ s/&aacute;/\\'87/g;
	$text =~ s/&eacute;/\\'8e/g;
	$text =~ s/&oacute;/\\'97/g;
	$text =~ s/&oslash;/\\'bf/g;
	$text =~ s/&#322;/\\uc0\\u322 /g;

	$text =~ s/&auml;/\\'8a/g;
	$text =~ s/&ouml;/\\'9a/g;
	$text =~ s/&uuml;/\\'9f/g;

	$text =~ s/&amp;/&/g;
	
	return $text;
}

# Convert HTML entities to TeX codes
sub html_entities_to_tex {
	my $text = shift;
	
	$text =~ s/&aacute;/\\'a/g;
	$text =~ s/&eacute;/\\'e/g;
	$text =~ s/&oacute;/\\'o/g;
	$text =~ s/&oslash;/{\\o}/g;
	$text =~ s/&#322;/{\\l}/g;

	$text =~ s/&auml;/\\"a/g;
	$text =~ s/&ouml;/\\"o/g;
	$text =~ s/&uuml;/\\"u/g;

	$text =~ s/&amp;/\\&/g;
	
	return $text;
}

# 
# Small reference of the RTF commands used here:
#
#  \fs28   switches to 14 point font (28 = 2 * 14)
#  \pard   reset to default paragraph properties
#
#  \ql     left-aligned text
#  \qr     right-aligned text
#  \qc     centered text
#  \qj     justified text
#
#  \b      turn on bold
#  \b0     turn off bold
#
# For more information: <http://latex2rtf.sourceforge.net/rtfspec.html>
#

sub begin_credits {
	my $title = shift;

	if ($mode eq "TEXT") {
		#print html_entities_to_ascii($title)."\n";
	} elsif ($mode eq "TEX") {
		print "% This file was generated by credits.pl. Do not edit by hand!\n";
		print '\section{Credits}' . "\n";
		print '\begin{trivlist}' . "\n";
	} elsif ($mode eq "RTF") {
		print '{\rtf1\mac\ansicpg10000' . "\n";
		print '{\fonttbl\f0\fswiss\fcharset77 Helvetica-Bold;\f1\fswiss\fcharset77 Helvetica;}' . "\n";
		print '{\colortbl;\red255\green255\blue255;\red0\green128\blue0;\red128\green128\blue128;}' . "\n";
		print '\vieww6920\viewh15480\viewkind0' . "\n";
		print "\n";
	} elsif ($mode eq "CPP") {
		print "// This file was generated by credits.pl. Do not edit by hand!\n";
		print "static const char *credits[] = {\n";
	} elsif ($mode eq "XML") {
		print "<!-- This file was generated by credits.pl. Do not edit by hand! -->\n";
		print "<appendix>\n";
		print "  <title>" . $title . "</title>\n";
		print "  <informaltable frame='none'>\n";
		print "  <tgroup cols='3' align='left' colsep='0' rowsep='0'>\n";
		print "  <colspec colname='start' colwidth='0.5cm'/>\n";
		print "  <colspec colname='name' colwidth='4cm'/>\n";
		print "  <colspec colname='job'/>\n";
		print "  <tbody>\n";
	} elsif ($mode eq "HTML") {
		print "<!-- This file was generated by credits.pl. Do not edit by hand! -->\n";
	}
}

sub end_credits {
	if ($mode eq "TEXT") {
	} elsif ($mode eq "TEX") {
		print '\end{trivlist}' . "\n";
		print "\n";
	} elsif ($mode eq "RTF") {
		print "}\n";
	} elsif ($mode eq "CPP") {
		print "};\n";
	} elsif ($mode eq "XML") {
		print "  </tbody>\n";
		print "  </tgroup>\n";
		print "  </informaltable>\n";
		print "</appendix>\n";
	} elsif ($mode eq "HTML") {
		print "\n";
	}
}

sub begin_section {
	my $title = shift;

	if ($mode eq "TEXT") {
		$title = html_entities_to_ascii($title);

		if ($section_level >= 2) {
			$title .= ":"
		}
		
		print "  " x $section_level . $title."\n";
		if ($section_level eq 0) {
			print "  " x $section_level . "*" x (length $title)."\n";
		} elsif ($section_level eq 1) {
			print "  " x $section_level . "-" x (length $title)."\n";
		}
	} elsif ($mode eq "TEX") {
		print '\item \textbf{';
		if ($section_level eq 0) {
			print '\LARGE';
		} elsif ($section_level eq 1) {
			print '\large';
		}
		print " " . html_entities_to_tex($title) . "}\n";
		print '\begin{list}{}{\setlength{\leftmargin}{0.2cm}}' . "\n";
	} elsif ($mode eq "RTF") {
		$title = html_entities_to_rtf($title);

		# Center text
		print '\pard\qc' . "\n";
		print '\f0\b';
		if ($section_level eq 0) {
			print '\fs40 ';
		} elsif ($section_level eq 1) {
			print '\fs32 ';
		}
		
		# Insert an empty line before this section header, *unless*
		# this is the very first section header in the file.
		if ($section_level > 0 || @section_count[0] > 0) {
			print "\\\n";
		}
		print '\cf2 ' . $title . "\n";
		print '\f1\b0\fs24 \cf0 \\' . "\n";
	} elsif ($mode eq "CPP") {
		if ($section_level eq 0) {
		  # TODO: Would be nice to have a 'fat' or 'large' mode for 
		  # headlines...
		  $title = html_entities_to_ascii($title);
		  print '"\\\\C\\\\c1""'.$title.'",' . "\n";
		  print '"\\\\C\\\\c0""",' . "\n";
		} else {
		  $title = html_entities_to_ascii($title);
		  print '"\\\\C\\\\c1""'.$title.'",' . "\n";
		}
	} elsif ($mode eq "XML") {
		print "  <row><entry namest='start' nameend='job'>";
		print "<emphasis role='bold'>" . $title . ":</emphasis>";
		print "</entry></row>\n";
	} elsif ($mode eq "HTML") {
		if ($section_level eq 0) {
			print "<div class='par-item'><div class='par-head'>$title</div><div class='par-content'>&nbsp;\n";
		} elsif ($section_level eq 1) {
			print "<div class='par-subhead'>$title</div>\n";
			print "<div class='par-subhead-dots'>&nbsp;</div>\n";
			print "<div class='par-subhead-content'>\n"
		} else {
			print "<span style='font-weight: bold'>$title:</span>\n";
		}
	}

	# Implicit start of person list on section level 2
	if ($section_level >= 2) {
		begin_persons();
	}
	@section_count[$section_level]++;
	$section_level++;
	@section_count[$section_level] = 0;
}

sub end_section {
	$section_level--;

	# Implicit end of person list on section level 2
	if ($section_level >= 2) {
		end_persons();
	}

	if ($mode eq "TEXT") {
		# nothing
	} elsif ($mode eq "TEX") {
		print '\end{list}' . "\n";
	} elsif ($mode eq "RTF") {
		# nothing
	} elsif ($mode eq "CPP") {
		print '"\\\\C\\\\c0""",' . "\n";
	} elsif ($mode eq "XML") {
		print "  <row><entry namest='start' nameend='job'> </entry></row>\n\n";
	} elsif ($mode eq "HTML") {
		if ($section_level eq 0) {
			print "</div></div>\n";
		} elsif ($section_level eq 1) {
			print "</div>\n";
		}
	}
}

sub begin_persons {
	if ($mode eq "HTML") {
		print "<table style='margin-left:2em; margin-bottom: 1em'>\n";
	} elsif ($mode eq "TEX") {
		print '\item  \begin{tabular}[h]{p{0.3\linewidth}p{0.6\linewidth}}' . "\n";
	}
}

sub end_persons {
	if ($mode eq "TEXT") {
		print "\n";
	} elsif ($mode eq "TEX") {
		print '  \end{tabular}' . "\n";
	} elsif ($mode eq "RTF") {
		# nothing
	} elsif ($mode eq "HTML") {
		print "</table>\n";
	}
}

sub add_person {
	my $name = shift;
	my $nick = shift;
	my $desc = shift;
	my $tab;
	
	if ($mode eq "TEXT") {
		$name = $nick if $name eq "";
		$name = html_entities_to_ascii($name);
		$desc = html_entities_to_ascii($desc);
		
		$tab = " " x ($section_level * 2 + 1);
		printf $tab."%-".$max_name_width.".".$max_name_width."s", $name;
		
		# Print desc wrapped
		if (length $desc > 0) {
		  my $inner_indent = ($section_level * 2 + 1) + $max_name_width + 3;
		  my $multitab = " " x $inner_indent;
		  print " - " . substr(wrap($multitab, $multitab, $desc), $inner_indent);
		}
		print "\n";
	} elsif ($mode eq "TEX") {
		$name = $nick if $name eq "";
		$name = html_entities_to_tex($name);
		$desc = html_entities_to_tex($desc);

		print "    $name & \\textit{$desc}\\\\\n";
	} elsif ($mode eq "RTF") {
		$name = $nick if $name eq "";
		$name = html_entities_to_rtf($name);

		# Center text
		print '\pard\qc' . "\n";
		# Activate 1.5 line spacing mode
		print '\sl360\slmult1';
		# The name
		print $name . "\\\n";
		# Description using italics
		if (length $desc > 0) {
			$desc = html_entities_to_rtf($desc);
			print '\pard\qc' . "\n";
			print "\\cf3\\i " . $desc . "\\i0\\cf0\\\n";
		}
	} elsif ($mode eq "CPP") {
		$name = $nick if $name eq "";
		$name = html_entities_to_ascii($name);

		print '"\\\\C\\\\c0""'.$name.'",' . "\n";

		# Print desc wrapped
		if (length $desc > 0) {
			$desc = html_entities_to_ascii($desc);
			print '"\\\\C\\\\c2""'.$desc.'",' . "\n";
		}
	} elsif ($mode eq "XML") {
		$name = $nick if $name eq "";
		print "  <row><entry namest='name'>" . $name . "</entry>";
		print "<entry>" . $desc . "</entry></row>\n";
	} elsif ($mode eq "HTML") {
		$name = "???" if $name eq "";
		print "<tr>";
		print "<td style='width:13em; padding:2px;'>".$name."</td>";
		if ($nick ne "") {
			print "<td style='width:10em; text-align: left;' class='news-author'>".$nick."</td>";
		} else {
			print "<td></td>";
		}
		print "<td>".$desc."</td>\n";
	}


}

sub add_paragraph {
	my $text = shift;
	my $tab;
	
	if ($mode eq "TEXT") {
		$tab = " " x ($section_level * 2 + 1);
		print wrap($tab, $tab, html_entities_to_ascii($text))."\n";
		print "\n";
	} elsif ($mode eq "TEX") {
		print '\item' . "\n";
		print $text;
		print "\n";
	} elsif ($mode eq "RTF") {
		# Center text
		print '\pard\qc' . "\n";
		print "\\\n";
		print $text . "\\\n";
	} elsif ($mode eq "CPP") {
		my $line_start = '"\\\\C\\\\c0""';
		my $line_end = '",';
		print $line_start . $text . $line_end . "\n";
		print $line_start . $line_end . "\n";
	} elsif ($mode eq "XML") {
		print "  <row><entry namest='start' nameend='job'>" . $text . "</entry></row>\n";
		print "  <row><entry namest='start' nameend='job'> </entry></row>\n\n";
	} elsif ($mode eq "HTML") {
		print "<p style='margin-left:2em; margin-bottom: 1em'>";
		print $text;
		print "</p>\n";
	}
}

#
# Now follows the actual credits data! The format should be clear, I hope.
# Note that people are sorted by their last name in most cases; in the
# 'Team' section, they are first grouped by category (Engine; porter; misc).
#

begin_credits("Credits");
  begin_section("ScummVM Team");
    begin_section("Project Leaders");
	  begin_persons();
		add_person('James Brown', 'ender', "");
		add_person('Max Horn', 'Fingolfin', "");
	  end_persons();
    end_section();


    begin_section("Engine Teams");
	  begin_section("SCUMM");
		  add_person("Torbj&ouml;rn Andersson", "eriktorbjorn", "");
		  add_person('James Brown', 'ender', "");
		  add_person("Jonathan Gray", "khalek", "");
		  add_person('Max Horn', 'Fingolfin', "");
		  add_person("Travis Howell", "Kirben", "");
		  add_person("Pawe&#322; Ko&#322;odziejski", "aquadran", "Codecs, iMUSE, Smush, etc.");
		  add_person("Eugene Sandulenko", "sev", "FT INSANE, MM NES, MM C64, game detection, Herc/CGA");
	  end_section();

	  begin_section("HE");
		  add_person("Jonathan Gray", "khalek", "");
		  add_person("Travis Howell", "Kirben", "");
		  add_person("Gregory Montoir", "cyx", "");
		  add_person("Eugene Sandulenko", "sev", "");
	  end_section();

	  begin_section("BASS");	# Beneath a Steel Sky
		  add_person("Robert G&ouml;ffringmann", "lavosspawn", "");
		  add_person("Oliver Kiehl", "olki", "");
		  add_person("Joost Peters", "joostp", "");
	  end_section();

	  begin_section("Broken Sword 1");
		  add_person("Robert G&ouml;ffringmann", "lavosspawn", "");
	  end_section();

	  begin_section("Broken Sword 2");
		  add_person("Torbj&ouml;rn Andersson", "eriktorbjorn", "");
		  add_person("Jonathan Gray", "khalek", "");
	  end_section();

	  begin_section("Cinematique evo 1");
		  add_person("Pawe&#322; Ko&#322;odziejski", "aquadran", "");
		  add_person("Gregory Montoir", "cyx", "");
		  add_person("Eugene Sandulenko", "sev", "");
	  end_section();

	  begin_section("FOTAQ");	# Flight of the Amazon Queen
		  add_person("David Eriksson", "twogood", "");
		  add_person("Gregory Montoir", "cyx", "");
		  add_person("Joost Peters", "joostp", "");
	  end_section();

	  begin_section("Gob");
		  add_person("Torbj&ouml;rn Andersson", "eriktorbjorn", "");
		  add_person("Sven Hesse", "DrMcCoy", "");
		  add_person("Willem Jan Palenstijn", "wjp", "");
		  add_person("Eugene Sandulenko", "sev", "");
	  end_section();

	  begin_section("Kyra");
		  add_person("Oystein Eftevaag", "vinterstum", "");
		  add_person("Gregory Montoir", "cyx", "");
		  add_person("Johannes Schickel", "LordHoto", "");
	  end_section();

	  begin_section("SAGA");
		  add_person("Torbj&ouml;rn Andersson", "eriktorbjorn", "");
		  add_person("Andrew Kurushin", "ajax16384", "");
		  add_person("Eugene Sandulenko", "sev", "");
	  end_section();

	  begin_section("Simon");
		  add_person("Travis Howell", "Kirben", "");
		  add_person("Oliver Kiehl", "olki", "");
	  end_section();
    end_section();


    begin_section("Backend Teams");
	  begin_section("Dreamcast");
		  add_person("Marcus Comstedt", "", "");
	  end_section();

	  begin_section("SymbianOS");
		  add_person("Jurgen Braam", "SumthinWicked", "");
		  add_person("Lars Persson", "AnotherGuest", "");
	  end_section();

	  begin_section("PalmOS");
		  add_person("Chris Apers", "chrilith ", "");
	  end_section();

	  begin_section("PocketPC / WinCE");
		  add_person("Nicolas Bacca", "arisme", "");
	  end_section();

	  begin_section("Playstation 2");
		  add_person("Robert G&ouml;ffringmann", "lavosspawn", "");
	  end_section();

	  begin_section("PSP (PlayStation Portable)");
		  add_person("Joost Peters", "joostp", "");
	  end_section();

	  begin_section("SDL (Win/Linux/OS X/etc.)");
		  add_person('Max Horn', 'Fingolfin', "");
		  add_person('Eugene Sandulenko', 'sev', "Asm routines, GFX layers");
	  end_section();
    end_section();

    begin_section("Other subsystems");
	  begin_persons();
		add_person("Jerome Fisher", "KingGuppy", "MT-32 emulator");
		add_person("Jochen Hoenicke", "hoenicke", "Speaker &amp; PCjr sound support, Adlib work");
	  end_persons();
    end_section();

    begin_section("Website (content)");
	  add_paragraph("All active team members");
    end_section();

    begin_section("Retired Team Members");
	  begin_persons();
		add_person("Tore Anderson", "tore", "Former Debian GNU/Linux maintainer");
		add_person("Ralph Brorsen", "painelf", "Help with GUI implementation");
		add_person("Jamieson Christian", "jamieson630", "iMUSE, MIDI, all things musical");
		add_person('Vincent Hamm', 'yazoo', "Co-Founder, original CinE engine author");
		add_person("Ruediger Hanke", "", "Port: MorphOS");
		add_person("Felix Jakschitsch", "yot", "Zak256 reverse engineering");
		add_person("Mutwin Kraus", "mutle", "Original MacOS porter");
		add_person("Peter Moraliyski", "ph0x", "Port: GP32");
		add_person('Jeremy Newman', 'laxdragon', "Former webmaster");
		add_person('Ludvig Strigeus', 'ludde', "Original ScummVM and SimonVM author");
		add_person("Lionel Ulmer", "bbrox", "Port: X11");
	  end_persons();
    end_section();
  end_section();


  begin_section("Other contributions");

	begin_section("Packages");
	  begin_section("AmigaOS 4");
		  add_person("Hans-J&ouml;rg Frieden", "", "");
		  add_person("Juha Niemim&auml;ki", "", "");
	  end_section();

	  begin_section("BeOS");
		  add_person("Stefan Parviainen", "", "");
	  end_section();

	  begin_section("Debian GNU/Linux");
		  add_person("David Weinehall", "tao", "");
	  end_section();

	  begin_section("Fedora / RedHat");
		  add_person("Willem Jan Palenstijn", "wjp", "");
	  end_section();

	  begin_section("Mac OS X");
		  add_person('Max Horn', 'Fingolfin', "");
	  end_section();

	  begin_section("OS/2");
		  add_person("Paul Smedley", "Creeping", "");
	  end_section();

	  begin_section("PocketPC 2002");
		  add_person("Kostas Nakos", "knakos", '');
	  end_section();

	  begin_section("SlackWare");
		  add_person("Robert Kelsen", "", "");
	  end_section();

	  begin_section("Win32");
		  add_person("Travis Howell", "Kirben", "");
	  end_section();

	  begin_section("Win64");
		  add_person("Chris Gray", "Psychoid", "");
	  end_section();
	end_section();

	begin_section("Website (design)");
	  begin_persons();
		  add_person("Dob&oacute; Bal&aacute;zs", "draven", "Website design");
		  add_person("Yaroslav Fedevych", "jafd", "HTML/CSS for the website");
		  add_person("David Jensen", "Tyst", "SVG logo conversion");
		  add_person("Jean Marc", "", 'ScummVM logo');
	  end_persons();
	end_section();

	begin_section("Code contributions");
	  begin_persons();
		  add_person("Stuart Caie", "", "Decoders for Simon 1 Amiga data files");
		  add_person("Paolo Costabel", "", "PSP port contributions");
		  add_person("Janne Huttunen", "", "V3 actor mask support, Dig/FT SMUSH audio");
		  add_person("Kov&aacute;cs Endre J&aacute;nos", "", "Several fixes for Simon1");
		  add_person("Jeroen Janssen", "", "Numerous readability and bugfix patches");
		  add_person("Andreas Karlsson", "Sprawl", "Initial port for EPOC/SymbianOS");
		  add_person("Claudio Matsuoka", "", 'Daily Linux builds');
		  add_person("Thomas Mayer", "", "PSP port contributions");
		  add_person("Mikesch Nepomuk", "", "MI1 VGA floppy patches");
		  add_person("Nicolas Noble", "pixels", "Config file and ALSA support");
		  add_person("", "Quietust", "Sound support for Amiga SCUMM V2/V3 games, MM NES support");
		  add_person("Andreas R&ouml;ver", "", "Broken Sword 1/2 MPEG2 cutscene support");
		  add_person("Edward Rudd", "", "Fixes for playing MP3 versions of MI1/Loom audio");
		  add_person("Daniel Schepler", "", "Final MI1 CD music support, initial Ogg Vorbis support");
		  add_person("Andr&eacute; Souza", "", "SDL-based OpenGL renderer");
		  add_person("Tim ???", "realmz", "Initial MI1 CD music support");
	  end_persons();
	end_section();

    add_paragraph("And to all the contributors, users, and beta testers we've missed. Thanks!");

  end_section();


  # HACK!
  $max_name_width = 16;

  begin_section("Special thanks to");
    begin_persons();
	  add_person("Sander Buskens", "", "For his work on the initial reversing of Monkey2");
	  add_person("", "Canadacow", "For the original MT-32 emulator");
	  add_person("Kevin Carnes", "", "For Scumm16, the basis of ScummVM's older gfx codecs");
	  add_person("Ivan Dubrov", "", "For contributing the initial version of the Gobliiins engine");
	  add_person("Joachim Eberhard", "joachimeberhard", "For numerous contributions to documentation");
	  add_person("", "Jezar", "For his freeverb filter implementation");
	  add_person("Jim Leiterman", "", "Various info on his FM-TOWNS/Marty SCUMM ports");
	  add_person("", "lloyd", "For deep tech details about C64 Zak &amp; MM");
	  add_person("Jimmi Th&oslash;gersen", "", "For ScummRev, and much obscure code/documentation");
	  add_person("", "Tristan", "For additional work on the original MT-32 emulator");
    end_persons();

  add_paragraph(
  "Tony Warriner and everyone at Revolution Software Ltd. for sharing ".
  "with us the source of some of their brilliant games, allowing us to ".
  "release Beneath a Steel Sky as freeware... and generally being ".
  "supportive above and beyond the call of duty.");

  add_paragraph(
  "John Passfield and Steve Stamatiadis for sharing the source of their ".
  "classic title, Flight of the Amazon Queen and also being incredibly ".
  "supportive.");

  add_paragraph(
  "Joe Pearce from The Wyrmkeep Entertainment Co. for sharing the source ".
  "of their famous title Inherit the Earth and always prompt replies to ".
  "our questions.");

  add_paragraph(
  "Aric Wilmunder, Ron Gilbert, David Fox, Vince Lee, and all those at ".
  "LucasFilm/LucasArts who made SCUMM the insane mess to reimplement ".
  "that it is today. Feel free to drop us a line and tell us what you ".
  "think, guys!");

  end_section();

end_credits();
