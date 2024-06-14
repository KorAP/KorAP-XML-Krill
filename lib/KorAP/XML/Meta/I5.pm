package KorAP::XML::Meta::I5;
use KorAP::XML::Meta::Base;
use Mojo::Util qw/url_escape/;

our $SIGLE_RE = qr/^([^_\/]+)(?:[_\/]([^\._\/]+?)(?:\.(.+?))?)?$/;

# STRING:
#   "pubPlace",
#   "textSigle",
#   "docSigle",
#   "corpusSigle",
#   "textType",
#   "textTypeArt",
#   "textTypeRef",
#   "textColumn",
#   "textDomain",
#   "availability",
#   "language",
#   "corpusID", // Deprecated!
#   "ID"        // Deprecated!
#
# TEXT:
#   "author",
#   "title",
#   "subTitle",
#   "corpusTitle",
#   "corpusSubTitle",
#   "corpusAuthor",
#   "docTitle",
#   "docSubTitle",
#   "docAuthor"
#
# KEYWORDS:
#   "textClass",
#   "foundries",
#   "keywords"
#
# STORE:
#   "docEditor",
#   "tokenSource",
#   "layerInfos",
#   "publisher",
#   "editor",
#   "fileEditionStatement",
#   "biblEditionStatement",
#   "reference",
#   "corpusEditor"
#   "distributor"
#   "internalLink"
#   "externalLink"
#
# DATE:
#   "pubDate",
#   "creationDate"


sub _squish ($) {
  for ($_[0]) {
    s!\s\s+! !g;
    s!^\s*!!;
    s!\s*$!!;
    s!^\-+$!!g;
  };
  $_[0];
};

# Parse meta data
# This will normally be parsed in the order corpus, doc, text
sub parse {
  my ($self, $dom, $type) = @_;

  my $lang = $self->lang;

  # Parse text sigle
  if ($type eq 'text' && !$self->text_sigle) {
    my $v = $dom->at('textSigle');
    if ($v) {
      $self->{_text_sigle} = _squish $v->text;
      if ($self->{_text_sigle} =~ $SIGLE_RE) {
        $self->{_text_sigle} = join('/', $1, $2, $3);
        $self->{_doc_sigle} = join('/', $1, $2);
        $self->{_corpus_sigle} = $1;
      };
    }
  }

  # Parse document sigle
  elsif ($type eq 'doc' && !$self->doc_sigle) {
    my $v = $dom->at('dokumentSigle');
    if ($v) {
      $self->{_doc_sigle} = $v->text;
      if ($self->{_doc_sigle} =~ $SIGLE_RE) {
        $self->{_doc_sigle} = join('/', $1, $2);
        $self->{_corpus_sigle} = $1;
      };
    }
  }

  # Parse corpus sigle
  elsif ($type eq 'corpus' && !$self->corpus_sigle) {
    my $v = $dom->at('korpusSigle');
    $self->{_corpus_sigle} = $v->text if $v;
  };

  # TODO: May have analytic AND monogr
  foreach my $analytic ($dom->at('analytic'), $dom->at('monogr')) {
    next unless $analytic;
    # There is an analytic element

    # Get title, subtitle, author, editor
    my $titles = $analytic->find('h\.title[type=main]');
    my $title;
    if ($lang) {
      $title = $titles->first(sub{ $_->attr('xml:lang') && lc($_->attr('xml:lang')) eq lc($lang) });
    };
    $title = $titles->first unless $title;

    my $sub_title;
    $titles    = $analytic->find('h\.title[type=sub]');
    if ($lang) {
      $sub_title = $titles->first(sub{ $_->attr('xml:lang') && lc($_->attr('xml:lang')) eq lc($lang) });
    };
    $sub_title = $titles->first unless $sub_title;

    my $author    = $analytic->at('h\.author');
    my $editor    = $analytic->at('editor');

    #if ($analytic->find('editor')->size > 1) {
    #  warn 'Mehr als ein Editor!';
    #  warn $analytic->find('editor')->join("\n");
    #};

    #if ($analytic->find('author')->size > 1) {
    #  warn 'Mehr als ein Autor!';
    #  warn $analytic->find('author')->join("\n");
    #};

    # Editor contains translator
    my $translator;
    if ($editor && $editor->attr('role') && $editor->attr('role') eq 'translator') {
      # Translator is only supported on the text level currently
      $translator = _squish $editor->all_text;
      $self->{A_translator} = $translator if $translator;
      $editor = undef;
    }
    else {
      $editor = $editor ? _squish $editor->all_text : undef;
    };

    $title     = $title     ? _squish $title->all_text     : undef;
    $sub_title = $sub_title ? _squish $sub_title->all_text : undef;
    $author    = $author    ? _squish $author->all_text    : undef;

    if (my $temp = $analytic->at('biblNote[n="url"]')) {
      my $url = _squish $temp->all_text;
      my $title = $temp->attr('rend') || $url;
      $self->{"A_${type}_external_link"} = $self->korap_data_uri($url, title => $title);
    };

    if (my $temp = $analytic->at('biblNote[n="url.ids"]')) {
      my $url = _squish $temp->all_text;
      my $title = $temp->attr('rend') || $url;
      $self->{"A_${type}_internal_link"} = $self->korap_data_uri($url, title => $title);
    };

    # Text meta data
    if ($type eq 'text') {
      unless ($self->{T_title} || $self->{T_sub_title}) {
        $self->{T_title} = _remove_prefix($title, $self->text_sigle) if $title;
        $self->{T_sub_title} = $sub_title if $sub_title;
      };
      $self->{A_editor} //= $editor       if $editor;
      $self->{T_author} //= $author       if $author;
    }

    # Doc meta data
    elsif ($type eq 'doc') {
      unless ($self->{T_doc_title} || $self->{T_doc_sub_title}) {
        $self->{T_doc_title} //= _remove_prefix($title, $self->doc_sigle) if $title;
        $self->{T_doc_sub_title} //= $sub_title if $sub_title;
      };
      $self->{T_doc_author} //= $author       if $author;
      $self->{A_doc_editor} //= $editor       if $editor;
    }

    # Corpus meta data
    elsif ($type eq 'corpus') {
      unless ($self->{T_corpus_title} || $self->{T_corpus_sub_title}) {
        $self->{T_corpus_title} //= _remove_prefix($title, $self->corpus_sigle) if $title;
        $self->{T_corpus_sub_title} //= $sub_title if $sub_title;
      };
      $self->{T_corpus_author} //= $author       if $author;
      $self->{A_corpus_editor} //= $editor       if $editor;
    };
  };

  # Not in analytic
  my ($titles, $title);
  if ($type eq 'corpus') {

    # Corpus title not yet given
    unless ($self->{T_corpus_title}) {
      if ($titles = $dom->find('fileDesc > titleStmt > c\.title')) {
        if ($lang) {
          $title = $titles->first(sub{ $_->attr('xml:lang') && lc($_->attr('xml:lang')) eq lc($lang) });
        };

        $title = $titles->first unless $title;

        if ($title) {
          $title = _squish($title->all_text);

          if ($title) {
            $self->{T_corpus_title} = _remove_prefix($title, $self->corpus_sigle);
          };
        };
      };
    };
  }

  # doc title
  elsif ($type eq 'doc') {
    unless ($self->{T_doc_title}) {
      if ($titles = $dom->find('fileDesc > titleStmt > d\.title')) {
        if ($lang) {
          $title = $titles->first(sub{ $_->attr('xml:lang') && lc($_->attr('xml:lang')) eq lc($lang) });
        };

        $title = $titles->first unless $title;

        if ($title) {
          $title = _squish($title->all_text);

          if ($title) {
            $self->{T_doc_title} = _remove_prefix($title, $self->doc_sigle);
          };
        };
      };
    };
  }

  # text title
  elsif ($type eq 'text') {
    unless ($self->{T_title}) {
      if ($titles = $dom->find('fileDesc > titleStmt > t\.title, fileDesc > titleStmt > title')) {
        if ($lang) {
          $title = $titles->first(sub{ $_->attr('xml:lang') && lc($_->attr('xml:lang')) eq lc($lang) });
        };

        $title = $titles->first unless $title;

        if ($title) {
          $title = _squish($title->all_text);

          if ($title) {
            $self->{T_title} = _remove_prefix($title, $self->text_sigle);
          };
        };
      };
    };
  };

  my $temp;


  # Parse Xenodata
  if ($temp = $dom->at('xenoData')) {
    $temp->find('meta')->each(
      sub {
        my $name = $_->attr('name');
        return unless $name;

        my $value = _squish $_->all_text;
        return unless $value;

        my $xtype = $_->attr('type');
        return unless $xtype;

        my $key = '';
        if ($xtype eq 'string') {
          $key = 'S_';
        } elsif ($xtype eq 'keyword') {
          $key = 'K_';
        } elsif ($xtype eq 'text') {
          $key = 'T_';
        } elsif ($xtype eq 'date') {
          $key = 'D_';
        } elsif ($xtype eq 'attachment') {
          $key = 'A_';
        } elsif ($xtype eq 'uri') {
          $key = 'A_';
          my $title = $_->att('desc');
          $value = $self->korap_data_uri($value, title => ($title // $value));
        } elsif ($xtype eq 'integer' || $xtype eq 'number') {
          $self->log->warn('Number is treated as integer');
          $key = 'I_';
        } else {
          $self->log->warn('Unknown xenodata type: ' . $xtype);
          return;
        };

        if (my $project = $_->attr('project')) {
          $key .= $project . '.';
        };

        # Prefix with type
        if ($type eq 'doc' || $type eq 'corpus') {
          $key .= $type . ucfirst($name);
        } else {
          $key .= $name;
        };

        if ($xtype eq 'keyword') {
          $self->{$key} //= [];
          push @{$self->{$key}}, $value;
        } else {
          $self->{$key} = $value;
        };
      }
    );
  };

  # Get PubPlace
  if ($temp = $dom->at('pubPlace')) {
    my $place_attr = $temp->attr('key');
    $self->{S_pub_place_key} = $place_attr if $place_attr;
    $temp = _squish $temp->all_text;
    $self->{S_pub_place} = $temp if $temp;
  };

  # Get Publisher
  if ($temp = $dom->at('imprint publisher')) {
    $temp = _squish $temp->all_text;
    $self->{A_publisher} = $temp if $temp;
  };

  # Get text type
  $temp = $dom->at('textDesc');
  my $temp_2;

  if ($temp) {
    if ($temp_2 = $temp->at('textType')) {
      $temp_2 = _squish $temp_2->all_text;
      $self->{S_text_type} = $temp_2 if $temp_2;
    };

    # Get text domain
    if ($temp_2 = $temp->at('textDomain')) {
      $temp_2 = _squish $temp_2->all_text;
      $self->{S_text_domain} = $temp_2 if $temp_2;
    };

    # Get text type art
    if ($temp_2 = $temp->at('textTypeArt')) {
      $temp_2 = _squish $temp_2->all_text;
      $self->{S_text_type_art} = $temp_2 if $temp_2;
    };

    # Get text type ref
    if ($temp_2 = $temp->at('textTypeRef')) {
      $temp_2 = _squish $temp_2->all_text;
      $self->{S_text_type_ref} = $temp_2 if $temp_2;
    };
  };

  state $NR_RE = qr/^\d+$/;
  state $REF_RE = qr!^[a-zA-Z0-9]+\/[a-zA-Z0-9]+\.\d+[\s:]\s*!;

  # Get pubDate
  my $pub_date = $dom->find('pubDate[type=year]');
  $pub_date->each(
    sub {
      my $x = shift->parent;
      my $year = $x->at('pubDate[type=year]') or return;
      $year = $year ? $year->text : 0;
      my $month = $x->at('pubDate[type=month]');
      $month = $month ? $month->text : 0;
      my $day = $x->at('pubDate[type=day]');
      $day = $day ? $day->text : 0;

      $year  = 0 if $year  !~ $NR_RE;
      $month = 0 if $month !~ $NR_RE;
      $day   = 0 if $day   !~ $NR_RE;

      my $date = '0000';
      if ($year) {
        if (length($year) <= 2) {
          # TEMP: This may change in the future!
          if ($year < 50) {
            $date = '20' . (length($year) == 1 ? '0' : '') . $year;
          } else {
            $date = '19' . $year;
          };
        }
        else {
          $date = $year;
        };
      };

      $date .= length($month) == 1 ? '0' . $month : $month;
      $date .= length($day) == 1 ? '0' . $day : $day;
      $self->{D_pub_date} = $date;
    });

  # creatDate
  my $create_date = $dom->at('creatDate');
  if ($create_date && $create_date->text) {
    $create_date = _squish $create_date->all_text;
    if (index($create_date, '-') > -1) {
      $self->log->warn("Creation date ranges are not supported");
      ($create_date) = split /\s*-\s*/, $create_date;
    };
    unless ($create_date =~ s{^(\d{4})$}{$1\.00\.00}) {
      unless ($create_date =~ s{^(\d{4})\.(\d{2})$}{$1\.$2\.00}) {
        $create_date =~ /^\d{4}\.\d{2}\.\d{2}$/;
      };
    };
    if ($create_date =~ /^\d{4}(?:\.\d{2}(?:\.\d{2})?)?$/) {
      $create_date =~ tr/\.//d;
      $self->{D_creation_date} = $create_date;
    };
  };


  $temp = $dom->at('textClass');
  if ($temp) {
    # Get textClasses
    my @topic;

    $temp->find("catRef")->each(
      sub {
        return unless $_->attr('target');
        my ($ign, @ttopic) = grep { $_ } map { _squish($_) } split('\.', $_->attr('target'));
        push(@topic, @ttopic);
      }
    );
    $self->{K_text_class} = [@topic] if @topic > 0;

    my $kws = $self->{K_keywords};
    my @keywords = $temp->find("h\.keywords > keyTerm")->map(sub {_squish($_) })->grep(sub { $_ })->each;
    push(@$kws, @keywords) if @keywords > 0;
  };

  if ($temp = $dom->at('biblFull editionStmt')) {
    $temp = _squish $temp->all_text;
    $self->{A_bibl_edition_statement} = $temp if $temp;
  };

  if ($temp = $dom->at('fileDesc')) {
    my $temp2;

    if (my $editionStmt = $temp->at('editionStmt')) {
      $temp2 = _squish $editionStmt->all_text;
      $self->{A_file_edition_statement} = $temp2 if $temp2;
    };

    if (my $availability = $temp->at('publicationStmt > availability')) {
      $temp2 = _squish $availability->all_text;
      $self->{S_availability} = $temp2 if $temp2;
    };

    if (my $distributor = $temp->at('publicationStmt > distributor')) {
      $temp2 = _squish $distributor->all_text;
      $self->{A_distributor} = $temp2 if $temp2;
    }
  };

  if ($temp = $dom->at('profileDesc > langUsage > language[id]')) {
    $self->{S_language} = $temp->attr('id') if $temp->attr('id');
  };


  # Some meta data only available in the corpus
  #if ($type eq 'corpus') {
  #}

  # Some meta data only reevant from the text
  if ($type eq 'text') {

    if ($temp = $dom->at('sourceDesc reference[type=complete]')) {
      if (my $ref_text = _squish $temp->all_text) {
        $ref_text =~ s!$REF_RE!!;
        $self->{A_reference} = $ref_text;

        # In case of Wikipedia texts, take the URL
        if ($ref_text =~ /URL:(http:.+?):\s+Wikipedia,\s+\d+\s*$/) {
          $self->{A_externalLink} = $self->korap_data_uri($1, title => 'Wikipedia');
        };
      };
    };

    $temp = $dom->at('textDesc > column');
    if ($temp && ($temp = _squish $temp->all_text)) {
      $self->{S_text_column} = $temp;
    };

    if ($temp = $dom->at('biblStruct biblScope[type=pp]')) {
      $temp = _squish $temp->all_text;
      if ($temp && $temp =~ m/(\d+)\s*-\s*(\d+)/) {
        $self->{A_src_pages} = $1 . '-' . $2;
      };
    };

    # DGD treatment
    if ($self->{T_title} && !$self->{A_externalLink} && $self->{_corpus_sigle} =~ /^(?:[AD]GD|FOLK)$/) {
      my $transcript = $self->{T_title};
      $transcript =~ s/_DF_\d+$//i;
      $self->{A_externalLink} = $self->korap_data_uri(
        'https://dgd.ids-mannheim.de/DGD2Web/ExternalAccessServlet?command=displayData&id=' .
          url_escape($transcript), title => 'DGD');
    }
  };

  return 1;
};


sub _remove_prefix {
  # This may render some titles wrong, e.g. 'VDI nachrichten 2014' ...
  return $_[0] unless $_[1];

  my ($title, $prefix) = @_;
  # $prefix =~ tr!_!/!;
  $prefix =~ s!^([^/]+?/[^/]+?)/!$1\.!;
  if (index($title, $prefix) == 0) {
    $title = substr($title, length($prefix));
    $title =~ s!^\s*[-;:,]\s*!!;
  };

  return _squish $title;
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

KorAP::XML::Meta::I5 - Parses I5 meta data of a KorAP-XML document

=head1 DESCRIPTION

Parses I5 meta data of a KorAP-XML document.

Following the data model, all 3 levels of metadata are parsed, while not all
metadata levels contain the same information. The precedence is that metadata
defined on the text level will override metadata on the document level. And
metadata on the document level will override metadata on the corpus level.

=head2 Metadata categories

Krill currently supports the following types of metadata to be indexed.
They differ especially in the way they can be used to construct a virtual corpus.

=over 2

=item B<String>

A simple string representation of a meta data field. Useful for fixed values,
such as I<corpusSigle> or I<language>.

=item B<Text>

A string representation that will be indexed as a text, so fulltext search
(like phrase search) is supported. Useful for values where partial matches are
useful, like I<title> or I<author>.

=item B<Keywords>

Multiple string representations. Identical to string, but supports multiple
values in the same field. Useful for multiple given values such as I<textClass>.

=item B<Attachment>

Values that can't be used for the construction of virtual corpora, but are stored
per document and can be retrieved. Useful for static data to be retrieved such as
I<reference> or I<externalLink>.

=item B<Date>

A representation of a date, that can later be used for date range queries to construct
virtual corpora. Useful for all date related information, such as I<pubDate> or I<createDate>.

=back

=head2 Metadata fields

Currently L<KorAP::XML::Meta::I5> recognizes and transfers the following fields, given as
a SCSS selector rule (plus C<@> for attribute values) followed by the field name and
the metadata category.
The order may indicate a field to be overwritten.

=over 2

=item B<On all levels>

  (analytic, monogr) editor[role=translator]   translator            ATTACHMENT
  pubPlace@key                                 pubPlaceKey           STRING
  pubPlace                                     pubPlace              STRING
  imprint publisher                            publisher             ATTACHMENT
  textDesc textType                            textType              STRING
  textDesc textDomain                          textDomain            STRING
  textDesc textTypeArt                         textTypeArt           STRING
  textDesc textTypeRef                         textTypeRef           STRING
  pubDate[type=year]
    & pubDate[type=month]
    & pubDate[type=day]                        pubDate               DATE
  creatDate                                    creationDate          DATE
  textClass catRef@target                      textClass             KEYWORDS
  textClass h\.keywords > keyTerm              keywords              KEYWORDS
  biblFull editionStmt                         biblEditionStatement  ATTACHMENT
  fileDesc editionStmt                         fileEditionStatement  ATTACHMENT
  fileDesc publicationStmt > availability      availability          STRING
  fileDesc publicationStmt > distributor       distributor           ATTACHMENT
  profileDesc > langUsage > language[id]@id    language              STRING

=item B<On text level>

  textSigle                                    textSigle             STRING
  fileDesc > titleStmt > t\.title              title                 TEXT
  (analytic, monogr) h\.title[type=main]       title                 TEXT
  (analytic, monogr) h\.title[type=sub]        subTitle              TEXT
  (analytic, monogr) h\.author                 author                TEXT
  (analytic, monogr) editor[role!=translator]  editor                ATTACHMENT
  sourceDesc reference[type=complete]          reference             ATTACHMENT
  textDesc > column                            textColumn            STRING
  biblStruct biblScope[type=pp]                srcPages              ATTACHMENT
  biblNote[n=url]                              textExternalLink
    & @rend                                                          ATTACHMENT
  biblNote[n="url.ids"]                        textInternalLink
    & @rend                                                          ATTACHMENT

=item B<On document level>

  dokumentSigle                                docSigle              STRING
  fileDesc > titleStmt > d\.title              docTitle              TEXT
  (analytic, monogr) h\.title[type=main]       docTitle              TEXT
  (analytic, monogr) h\.title[type=sub]        docSubTitle           TEXT
  (analytic, monogr) h\.author                 docAuthor             TEXT
  (analytic, monogr) editor[role!=translator]  docEditor             ATTACHMENT
  biblNote[n=url]                              docExternalLink
    & @rend                                                          ATTACHMENT
  biblNote[n="url.ids"]                        docInternalLink
    & @rend                                                          ATTACHMENT

=item B<On corpus level>

  korpusSigle                                  corpusSigle           STRING
  fileDesc > titleStmt > c\.title              corpusTitle           TEXT
  (analytic, monogr) h\.title[type=main]       corpusTitle           TEXT
  (analytic, monogr) h\.title[type=sub]        corpusSubTitle        TEXT
  (analytic, monogr) h\.author                 corpusAuthor          TEXT
  (analytic, monogr) editor[role!=translator]  corpusEditor          ATTACHMENT
  biblNote[n=url]                              corpusExternalLink
    & @rend                                                          ATTACHMENT
  biblNote[n="url.ids"]                        corpudInternalLink
    & @rend                                                          ATTACHMENT

=back

Some fields are specially formated, like C<srcPages> or dates.
In case of Wikipedia texts, C<sourceDesc reference[type=complete]> will be
turned into an C<externalLink>. In case of DGD/AGD documents, an external link
to the DGD will be created as C<externalLink>.


=head1 AVAILABILITY

  https://github.com/KorAP/KorAP-XML-Krill


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2020, L<IDS Mannheim|https://www.ids-mannheim.de/>
Author: L<Nils Diewald|https://nils-diewald.de/>

KorAP::XML::Krill is developed as part of the
L<KorAP|https://korap.ids-mannheim.de/>
Corpus Analysis Platform at the
L<Institute for the German Language (IDS)|https://www.ids-mannheim.de/>,
member of the
L<Leibniz-Gemeinschaft|https://www.leibniz-gemeinschaft.de/en/>
and supported by the L<KobRA|http://www.kobra.tu-dortmund.de> project,
funded by the
L<Federal Ministry of Education and Research (BMBF)|http://www.bmbf.de/en/>.

KorAP::XML::Krill is free software published under the
L<BSD-2 License|https://raw.githubusercontent.com/KorAP/KorAP-XML-Krill/master/LICENSE>.

=cut
