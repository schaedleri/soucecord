use strict;
use warnings;

# �N���X�^�[�����ƃt�B���^�����O
sub generate_clusters {
    my ($file_path, $interval, $accession_file, $cluster_output_file, $filtered_output_file) = @_;

    print "Generating clusters from $file_path with interval $interval...\n";

    # ���̓f�[�^�̓ǂݍ���
    # �f�[�^�̓ǂݍ���
      open my $fh, '<', $file_path or die "Could not open file '$file_path': $!";
      my @data;
      <$fh>;  # �w�b�_�[�s���X�L�b�v
      
      while (<$fh>) {
          chomp;  # �s�S�̂̉��s���폜
          my @fields = map { s/^\s+|\s+$//gr } split /\t/;  # �e�t�B�[���h�̑O��̋󔒂���s���폜
          push @data, {
              Accession         => $fields[0],
              Begin             => $fields[1],
              End               => $fields[2],
              Name              => $fields[5],
              Protein_accession => $fields[10],
              Locus_tag         => $fields[12]
          };
      }
      close $fh;


    # �N���X�^�[����
    my @clusters;
    my @current_cluster = ($data[0]);

    for my $i (1 .. $#data) {
        my $gap = $data[$i]{Begin} - $data[$i-1]{End};
        if ($gap <= $interval) {
            push @current_cluster, $data[$i];
        } else {
            push @clusters, [@current_cluster];
            @current_cluster = ($data[$i]);
        }
    }
    push @clusters, [@current_cluster] if @current_cluster;

    # accession.txt����A�N�Z�b�V�����ԍ���ǂݍ���
    open my $afh, '<', $accession_file or die "Could not open file '$accession_file': $!";
    my %accessions;
    while (<$afh>) {
        chomp;
        my $acc = $_;
        $acc =~ s/^\s+|\s+$//g;
        $accessions{uc($acc)} = 1;
    }
    close $afh;

    # �N���X�^�[�̏o��
    open my $out_fh, '>', $cluster_output_file or die "Could not open file '$cluster_output_file': $!";
    print $out_fh "Accession\tBegin\tEnd\tName\tProtein accession\tLocus tag\tMatch\n";

    my $output_cluster_count = 0;
    for my $cluster (@clusters) {
        next if scalar(@$cluster) == 1;

        my $all_hypothetical = 1;
        for my $gene (@$cluster) {
            if ($gene->{Name} ne 'hypothetical protein') {
                $all_hypothetical = 0;
                last;
            }
        }
        next if $all_hypothetical;

        for my $gene (@$cluster) {
            my $match_indicator = exists $accessions{uc($gene->{Protein_accession})} ? "[MATCHED]" : "[NOT MATCHED]";
            
            # ���s���܂މ\����r��
            chomp($match_indicator);
            $match_indicator =~ s/\R//g;  # �S�Ẳ��s���폜
            
            # �f�[�^��1�s�œ���I�ɏo��
            print $out_fh join("\t", 
                $gene->{Accession}, 
                $gene->{Begin}, 
                $gene->{End}, 
                $gene->{Name}, 
                $gene->{Protein_accession}, 
                $gene->{Locus_tag}, 
                $match_indicator
            ), "\n";
        }
        print $out_fh "\n";  # �N���X�^�[�Ԃ̋�؂�Ƃ��ċ�s���o��
        $output_cluster_count++;
    }
    close $out_fh;

    print "Results written to $cluster_output_file\n";
    print "Number of clusters written: $output_cluster_count\n";

    # �t�B���^�����O����
    open my $cfh, '<', $cluster_output_file or die "Could not open file '$cluster_output_file': $!";
    open my $fout_fh, '>', $filtered_output_file or die "Could not open file '$filtered_output_file': $!";

    my $header = <$cfh>;
    print $fout_fh $header;

    my $filtered_cluster_count = 0;
    my @filter_current_cluster;

    while (<$cfh>) {
        chomp;
        if ($_ eq '') {
            my $cluster_contains_accession = 0;

            for my $gene (@filter_current_cluster) {
                if (defined $gene->{Protein_accession} && exists $accessions{uc($gene->{Protein_accession})}) {
                    $cluster_contains_accession = 1;
                    last;
                }
            }

            if ($cluster_contains_accession) {
                for my $gene (@filter_current_cluster) {
                    my $match_indicator = exists $accessions{uc($gene->{Protein_accession})} ? "[MATCHED]" : "[NOT MATCHED]";
                    print $fout_fh join("\t", 
                        $gene->{Accession}, 
                        $gene->{Begin}, 
                        $gene->{End}, 
                        $gene->{Name}, 
                        $gene->{Protein_accession}, 
                        $gene->{Locus_tag}, 
                        $match_indicator
                    ), "\n";
                }
                print $fout_fh "\n";
                $filtered_cluster_count++;
            }
            @filter_current_cluster = ();
        } else {
            my @fields = split /\t/;
            push @filter_current_cluster, {
                Accession         => $fields[0],
                Begin             => $fields[1],
                End               => $fields[2],
                Name              => $fields[3],
                Protein_accession => $fields[4],
                Locus_tag         => $fields[5]
            };
        }
    }

    if (@filter_current_cluster) {
        my $cluster_contains_accession = 0;

        for my $gene (@filter_current_cluster) {
            if (defined $gene->{Protein_accession} && exists $accessions{uc($gene->{Protein_accession})}) {
                $cluster_contains_accession = 1;
                last;
            }
        }

        if ($cluster_contains_accession) {
            for my $gene (@filter_current_cluster) {
                my $match_indicator = exists $accessions{uc($gene->{Protein_accession})} ? "[MATCHED]" : "[NOT MATCHED]";
                print $fout_fh join("\t", 
                    $gene->{Accession}, 
                    $gene->{Begin}, 
                    $gene->{End}, 
                    $gene->{Name}, 
                    $gene->{Protein_accession}, 
                    $gene->{Locus_tag}, 
                    $match_indicator
                ), "\n";
            }
            print $fout_fh "\n";
            $filtered_cluster_count++;
        }
    }

    close $cfh;
    close $fout_fh;

    print "Filtered clusters written to $filtered_output_file\n";
    print "Number of clusters matching accessions: $filtered_cluster_count\n";

    return $filtered_output_file;
}

# �t�B���^�����O��̃f�[�^���
sub analyze_filtered_data {
    my ($filtered_file, $accession_file, $output_file) = @_;

    print "Analyzing filtered data: $filtered_file\n";

    # �A�N�Z�b�V�����f�[�^��ǂݍ���
    open my $afh, '<', $accession_file or die "Could not open file '$accession_file': $!";
    my %accessions = map { chomp; s/^\s+|\s+$//gr => 1 } <$afh>;  # �󔒍폜��ǉ�
    close $afh;

    # �f�o�b�O: �A�N�Z�b�V�����ԍ��̐����m�F
    print "Total accessions loaded from $accession_file: ", scalar(keys %accessions), "\n";

    open my $fh, '<', $filtered_file or die "Could not open file '$filtered_file': $!";
    my @data;
    <$fh>;  # �w�b�_�[�s���X�L�b�v

    my $id = 1;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line eq '';  # ��s�̓X�L�b�v
        my @fields = map { s/^\s+|\s+$//gr } split /\t/, $line;  # �t�B�[���h�̋󔒂��폜
        push @data, {
            ID                => $id++,
            Accession         => $fields[0],
            Begin             => $fields[1],
            End               => $fields[2],
            Name              => $fields[3],
            Protein_accession => $fields[4],
            Locus_tag         => $fields[5]
        };
    }
    close $fh;

    # �f�o�b�O: �ǂݍ��܂ꂽ�f�[�^�̌������m�F
    print "Total records loaded from $filtered_file: ", scalar(@data), "\n";

    # MATCH�f�[�^���擾
    my @matches = grep { 
        print "Checking Protein_accession: ", $_->{Protein_accession}, "\n";  # �f�o�b�O�o��
        exists $accessions{uc($_->{Protein_accession})} 
    } @data;

    print "Number of MATCH records found: ", scalar(@matches), "\n";

    if (!@data) {
        print "Filtered data is empty. Skipping NOT MATCH analysis.\n";
        return;
    }

    if (!@matches) {
        print "No MATCH data found in filtered file. Skipping NOT MATCH analysis.\n";
        return;
    }

    find_and_write_nearest_not_matches(\@data, \%accessions, $output_file);
}

# �ŋߖTNOT MATCH��T��
sub find_and_write_nearest_not_matches {
    my ($data, $accessions, $output_file) = @_;

    print "Starting nearest NOT MATCH search...\n";

    # MATCH��NOT MATCH�𕪗�
    my @matches = grep { exists $accessions->{uc($_->{Protein_accession})} } @$data;
    my @not_matches = grep { !exists $accessions->{uc($_->{Protein_accession})} } @$data;

    if (!@matches) {
        print "No MATCH data found.\n";
        return;
    }
    if (!@not_matches) {
        print "No NOT MATCH data found.\n";
        return;
    }

    # �o�̓t�@�C�����J��
    open my $out_fh, '>', $output_file or die "Could not open file '$output_file': $!";
    print $out_fh "MATCH\tSelected NOT MATCH\tDistance\tMATCH Details\tNOT MATCH Details\n";

    for my $match (@matches) {
        my $shortest_distance = undef;
        my $nearest_not_match = undef;

        for my $not_match (@not_matches) {
            # �O��̋������v�Z
            my $distance;
            if ($not_match->{ID} < $match->{ID}) {
                $distance = $match->{Begin} - $not_match->{End}; # �O
            } elsif ($not_match->{ID} > $match->{ID}) {
                $distance = $not_match->{Begin} - $match->{End}; # ��
            } else {
                next;
            }

            # �ŒZ�������L�^
            if (!defined($shortest_distance) || $distance < $shortest_distance) {
                $shortest_distance = $distance;
                $nearest_not_match = $not_match;
            }
        }

        # �o��
        if ($nearest_not_match) {
            my $match_info = join(";", map { "$_=$match->{$_}" } qw(Protein_accession Begin End Name Locus_tag));
            my $not_match_info = join(";", map { "$_=$nearest_not_match->{$_}" } qw(Protein_accession Begin End Name Locus_tag));
            print $out_fh join("\t", 
                $match->{Protein_accession},
                $nearest_not_match->{Protein_accession} // "N/A",
                $shortest_distance,
                $match_info,
                $not_match_info
            ), "\n";
        }
    }

    close $out_fh;
    print "Nearest NOT MATCH results written to $output_file\n";
}

# ���C������
print "Enter the maximum interval for clustering: ";
my $interval = <STDIN>;
chomp($interval);

my $file_path = 'Mschaedleri.tsv';
my $accession_file = 'accession_afterpsi.txt';

my $cluster_output_file = "interval$interval.tsv";
my $filtered_output_file = "filtered_$cluster_output_file";
my $nearest_not_matches_file = "nearest_not_matches_interval$interval.tsv";

my $filtered_data = generate_clusters($file_path, $interval, $accession_file, $cluster_output_file, $filtered_output_file);
analyze_filtered_data($filtered_output_file, $accession_file, $nearest_not_matches_file);