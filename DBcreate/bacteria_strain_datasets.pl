use strict;
use warnings;
use File::Basename;
use Parallel::ForkManager;

# 入力ファイルと出力設定
my $input_file = 'bacteria_strain.tsv';
my $failed_file = 'failed_microbes_bacteria.txt';
my $output_dir = 'bacteria_strain';

# 出力フォルダの作成
mkdir $output_dir unless -d $output_dir;

# ファイルのオープン
open my $fh, '<', $input_file or die "Could not open file '$input_file': $!";
open my $failed_fh, '>>', $failed_file or die "Could not open file '$failed_file': $!"; # 追記モード

# 並列処理の設定
my $pm = Parallel::ForkManager->new(4);
my $line_count = `wc -l < $input_file` + 0;
my $processed = 0;

# ヘッダー行をスキップ
my $header = <$fh>;

# 各行の処理
while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^\s*$/;

    # 各列をタブ区切りで分割
    my @columns = split /\t/, $line;
    my $assembly_accession = $columns[0];  # Assembly Accession
    my $organism_name = $columns[2];      # Organism Name

    # 微生物名をファイル名に使用できる形式に変換
    $organism_name =~ s/[^\w]/_/g;
    my $output_file = "${output_dir}/${organism_name}_protein.zip";

    # 既存ファイルチェック
    if (-e $output_file) {
        print "Skipping $organism_name (Accession: $assembly_accession): File already exists.\n";
        $processed++;
        next;
    }

    $pm->start and next;

    # ダウンロードコマンド
    my $command = qq(datasets download genome accession $assembly_accession --assembly-level "complete" --assembly-source 'RefSeq' --reference --filename "$output_file" --include protein);

    # コマンドの実行
    my $result = system($command);

    # 再試行処理
    if ($result != 0) {
        warn "First attempt failed for $organism_name (Accession: $assembly_accession). Retrying...\n";
        my $retry_command = qq(datasets download genome accession $assembly_accession --assembly-source 'RefSeq' --reference --filename "$output_file" --include protein);
        $result = system($retry_command);

        # 再試行が失敗した場合
        if ($result != 0) {
            my $exit_code = $? >> 8;
            print $failed_fh "$organism_name (Accession: $assembly_accession) - Failed with exit code $exit_code\n";
        }
    }

    $pm->finish;
    $processed++;
    printf "Processed %d/%d (%.2f%%)\n", $processed, $line_count, ($processed / $line_count) * 100;
}

$pm->wait_all_children;

# ファイルを閉じる
close $fh;
close $failed_fh;

print "Download completed. Check $output_dir and $failed_file for details.\n";
