#!/usr/bin/perl -w
use strict;
use 5.010;

undef $/;
my ($title, $author, $toc_list);
($title, $author) = @ARGV;
open HTML, "<", "$title.html" or die "open ${title}.html err";
my $html = <HTML>;
close HTML;
&make_opf;
&make_toc;
&make_content;

# ${title}.opf
sub make_opf {
    my $xml = <<ENDXML;
<?xml version="1.0" encoding="utf-8"?>
<package unique-identifier="uid">
<metadata>
  <dc-metadata
    xmlns:dc="http://purl.org/metadata/dublin_core"
    xmlns:oebpackage="http://openebook.org/namespaces/oeb-package/1.0/">
    <dc:Title>$title</dc:Title>
    <dc:Creator>$author</dc:Creator>
    <dc:Producer>kindlegen</dc:Producer>
    <dc:Language>zh-cn</dc:Language>
    </dc-metadata>
    <x-metadata>
      <output encoding="utf-8" content-type="text/x-oeb1-document"></output>
    </x-metadata>
</metadata>
<manifest>
  <item id="item2" media-type="text/x-oeb1-document" href="${title}.html"></item>
  <item id="item1" media-type="text/x-oeb1-document" href="${title}TOC.html"></item>
  <item id="My_Table_of_Contents" media-type="application/x-dtbncx+xml" href="${title}.ncx"/>
</manifest>
<spine toc="My_Table_of_Contents" pageList>
 <itemref idref="item1"/>
</spine>
<tours>
</tours>
<guide>
  <reference type="toc" title="Table of Contents" href="${title}TOC.html#toc"></reference>
  <reference type="text" title="start" href="${title}.html#start"></reference>
</guide>
</package>
ENDXML
    open my $opf_fh, ">", "${title}.opf" or die "write opf file fail";
    print $opf_fh $xml;
    close $opf_fh;
    say "make opf file success";
}

sub make_toc {
    &make_toc_html;
    &make_toc_ncx;
}

# ${title}TOC.html
sub make_toc_html {
    my $toc_html = <<HTMLHEAD;
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head><title>Table of Contents</title></head>

<body>
<div>
<a id="toc"></a>
 <center><h1><b>Table of Contents</b></h1></center>
 <br />
HTMLHEAD
    if ($html =~ m#<div id="text-table-of-contents">(.+?</ul>)#s) {
        $toc_list = $1;
    } else {
        die "match error";
    }
    $toc_html = $toc_html . $toc_list . "\n</div>\n</body>\n</html>";
    open my $toc_fh, ">", "${title}TOC.html" or die "open ${title}TOC.html err";
    print $toc_fh $toc_html;
    close $toc_fh;
    say "make toc html success";
}
# ${title}.ncx
sub make_toc_ncx {
    my @toc_array;
    my $index;
    while (not $toc_list =~ m/\G\z/gc) {
        if ($toc_list =~ m|\G^.*?<a href="#(org[a-z0-9]+)">(.+?)</a></li>$|mgc) {
            my ($id, $value) = ($1, $2);
            my %node = ( id => $id, value => $value);
            push @toc_array, \%node;
            $index++;
            say "push $index line: $id, $value";
        } elsif ($toc_list =~ m/\G^.*$/mgc) {
        } elsif ($toc_list =~ m/\G\n/mgc) {
        } else {
            die "$0 this shouldn't happen!";
        }
    }
    my $ncx = <<NCXHEAD;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN"
  "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/"
  version="2005-1" xml:lang="en-US">
<head>
<meta name="dtb:uid" content="uid"/>
<meta name="dtb:depth" content="1"/>
<meta name="dtb:totalPageCount" content="0"/>
<meta name="dtb:maxPageNumber" content="0"/>
</head>
<docTitle><text>$title</text></docTitle>
<docAuthor><text>$author</text></docAuthor>
<navMap>
<navPoint id="navpoint-1" playOrder="1">
<navLabel><text>目录</text></navLabel>
<content src="${title}TOC.html"/>
</navPoint>
<navPoint id="navpoint-2" playOrder="2">
<navLabel><text>开始</text></navLabel>
<content src="${title}.html"/>
</navPoint>
NCXHEAD
    $index = 3;
    for (@toc_array) {
        my $item = <<ITEM;
<navPoint  id="$$_{id}" playOrder="$index">
<navLabel><text>$$_{value}</text></navLabel>
<content src="${title}.html#$$_{id}"/>
</navPoint>
ITEM
        $ncx .= $item;
        $index++;
    }
    $ncx .= "</ncx>";
    say "build ncx success";
    open my $ncx_fh, ">", "${title}.ncx" or die "open ncx fail";
    print $ncx_fh $ncx;
    close $ncx_fh;
}


# ${title}.html
sub make_content {
    open HTML, ">", "${title}.html" or die "write content html fail";
    my $replace = '<a id="start"></a>';
    $html =~ s|\A(.*?)(<h\d class="title">.*?</h\d>).*?<div id="table-of-contents">.*?</div>\s*</div>(.*)\Z|$1$replace$2$3|s;
    $html =~ s#\A(.*?)<style type="text/css">.*?</style>(.*)\Z#$1$2#s;
    while ( $html =~ s#\A(.*?)<script type="text/.*?</script>(.*)\Z#$1$2#s ) {};
    print HTML $html;
    close HTML;
}
