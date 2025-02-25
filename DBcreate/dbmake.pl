#!/usr/bin/perl
use strict;
use warnings;
use File::Path qw(make_path);

# 入力ファイルのプレフィックス
my $input_prefix = "BS_all_proteins_unique_deduped";
my $output_base_dir = "/source/bacteria_strain_DB";

# 繰り返し処理でデータベースを作成
for my $i (0 .. 9) {
    my $input_file = "${input_prefix}${i}.faa";
    my $output_dir = "${output_base_dir}/DB${i}";
    my $output_db = "${output_dir}/BSDB${i}";
    my $log_file = "${output_dir}/BSDB${i}.log.txt";

    # 出力ディレクトリを作成
    if (!-d $output_dir) {
        make_path($output_dir) or die "Cannot create directory $output_dir: $!";
        print "ディレクトリ作成: $output_dir\n";
    }

    # makeblastdbコマンドを構築
    my $cmd = "makeblastdb -in $input_file -dbtype prot -parse_seqids -out $output_db -logfile $log_file -hash_index";
    print "コマンド実行中: $cmd\n";

    # コマンドを実行
    system($cmd) == 0 or die "Error running makeblastdb for $input_file: $!";
    print "データベース作成完了: $output_db\n";
}

print "全データベース作成完了。\n";
