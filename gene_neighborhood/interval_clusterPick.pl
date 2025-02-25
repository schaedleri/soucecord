use strict;
use warnings;

# クラスター生成とフィルタリング
sub generate_clusters {
    my ($file_path, $interval, $accession_file, $cluster_output_file, $filtered_output_file) = @_;

    print "Generating clusters from $file_path with interval $interval...\n";

    # 入力データの読み込み
    # データの読み込み
      open my $fh, '<', $file_path or die "Could not open file '$file_path': $!";
      my @data;
      <$fh>;  # ヘッダー行をスキップ
      
      while (<$fh>) {
          chomp;  # 行全体の改行を削除
          my @fields = map { s/^\s+|\s+$//gr } split /\t/;  # 各フィールドの前後の空白や改行を削除
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


    # クラスター生成
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

    # accession.txtからアクセッション番号を読み込む
    open my $afh, '<', $accession_file or die "Could not open file '$accession_file': $!";
    my %accessions;
    while (<$afh>) {
        chomp;
        my $acc = $_;
        $acc =~ s/^\s+|\s+$//g;
        $accessions{uc($acc)} = 1;
    }
    close $afh;

    # クラスターの出力
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
            
            # 改行を含む可能性を排除
            chomp($match_indicator);
            $match_indicator =~ s/\R//g;  # 全ての改行を削除
            
            # データを1行で統一的に出力
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
        print $out_fh "\n";  # クラスター間の区切りとして空行を出力
        $output_cluster_count++;
    }
    close $out_fh;

    print "Results written to $cluster_output_file\n";
    print "Number of clusters written: $output_cluster_count\n";

    # フィルタリング処理
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

# フィルタリング後のデータ解析
sub analyze_filtered_data {
    my ($filtered_file, $accession_file, $output_file) = @_;

    print "Analyzing filtered data: $filtered_file\n";

    # アクセッションデータを読み込み
    open my $afh, '<', $accession_file or die "Could not open file '$accession_file': $!";
    my %accessions = map { chomp; s/^\s+|\s+$//gr => 1 } <$afh>;  # 空白削除を追加
    close $afh;

    # デバッグ: アクセッション番号の数を確認
    print "Total accessions loaded from $accession_file: ", scalar(keys %accessions), "\n";

    open my $fh, '<', $filtered_file or die "Could not open file '$filtered_file': $!";
    my @data;
    <$fh>;  # ヘッダー行をスキップ

    my $id = 1;
    while (my $line = <$fh>) {
        chomp $line;
        next if $line eq '';  # 空行はスキップ
        my @fields = map { s/^\s+|\s+$//gr } split /\t/, $line;  # フィールドの空白を削除
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

    # デバッグ: 読み込まれたデータの件数を確認
    print "Total records loaded from $filtered_file: ", scalar(@data), "\n";

    # MATCHデータを取得
    my @matches = grep { 
        print "Checking Protein_accession: ", $_->{Protein_accession}, "\n";  # デバッグ出力
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

# 最近傍NOT MATCHを探す
sub find_and_write_nearest_not_matches {
    my ($data, $accessions, $output_file) = @_;

    print "Starting nearest NOT MATCH search...\n";

    # MATCHとNOT MATCHを分離
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

    # 出力ファイルを開く
    open my $out_fh, '>', $output_file or die "Could not open file '$output_file': $!";
    print $out_fh "MATCH\tSelected NOT MATCH\tDistance\tMATCH Details\tNOT MATCH Details\n";

    for my $match (@matches) {
        my $shortest_distance = undef;
        my $nearest_not_match = undef;

        for my $not_match (@not_matches) {
            # 前後の距離を計算
            my $distance;
            if ($not_match->{ID} < $match->{ID}) {
                $distance = $match->{Begin} - $not_match->{End}; # 前
            } elsif ($not_match->{ID} > $match->{ID}) {
                $distance = $not_match->{Begin} - $match->{End}; # 後
            } else {
                next;
            }

            # 最短距離を記録
            if (!defined($shortest_distance) || $distance < $shortest_distance) {
                $shortest_distance = $distance;
                $nearest_not_match = $not_match;
            }
        }

        # 出力
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

# メイン処理
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