#!/usr/bin/perl
use strict;
use warnings;

# ディレクトリの設定
my $txt_dir = "/source/blast/Mucispirillum_schaedleri_ASF457/BS_result/hypothetical";
my $fasta_dir = "/source/blast/Mucispirillum_schaedleri_ASF457";
my $output_dir = "/source/blast/Mucispirillum_schaedleri_ASF457/BS_result/PSIresult/";
my $db_path = "/source/DB/bacteria_strain_DB/DBall/BSDBall";

# 出力ディレクトリの作成
mkdir $output_dir unless -d $output_dir;

# txtディレクトリ内のファイルを読み込む
opendir(my $dh, $txt_dir) or die "Cannot open directory $txt_dir: $!";
my @txt_files = grep { /\.txt$/ && -f "$txt_dir/$_" } readdir($dh);
closedir($dh);

# 各txtファイルを処理
foreach my $txt_file (@txt_files) {
    # ファイル名の拡張子を取り除く
    my ($base_name) = $txt_file =~ /^(.*)\.txt$/;

    # 対応するfastaファイルを確認
    my $fasta_file = "$fasta_dir/$base_name.fasta";
    if (-e $fasta_file) {
        print "Processing $fasta_file with PSIBLAST...\n";

        # PSIBLASTコマンドを構築
        my $output_file = "$output_dir/$base_name.txt";
        my $psiblast_cmd = "psiblast -query $fasta_file -db $db_path -max_target_seqs 100 ".
                           "-out $output_file -evalue 0.05 -num_iterations 3 ".
                           "-threshold 0.0001 -num_threads 10";

        # コマンドを実行
        system($psiblast_cmd) == 0
            or warn "Failed to run PSIBLAST for $fasta_file: $!";
    } else {
        warn "Warning: Corresponding fasta file $fasta_file not found for $txt_file.\n";
    }
}

print "All processing completed.\n";
