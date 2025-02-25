use strict;
use warnings;
use File::Find;
use File::Basename;

# 収集元のルートディレクトリ
my $root_dir = '/source/bacteria_strain/';
# 統合先の出力ファイル
my $output_file = 'all_proteins_unique.faa';
my $summary_txt = 'BS_statistics_summary.txt';
my $summary_tsv = 'BS_statistics_summary.tsv';

# 再帰的にprotein.faaを探し、その内容を格納
my @fasta_files;
find(
    sub {
        if ($_ eq 'protein.faa') {
            push @fasta_files, $File::Find::name;
        }
    },
    $root_dir
);

# 収集結果を確認
if (!@fasta_files) {
    die "No 'protein.faa' files found in $root_dir\n";
}

print "Found ", scalar(@fasta_files), " protein.faa files.\n";

# ユニークなシーケンスを保存するためのハッシュ
my %unique_sequences;
my %file_stats;  # 各ファイルの統計情報

# 各ファイルを処理してシーケンスを収集
foreach my $fasta_file (@fasta_files) {
    open my $in_fh, '<', $fasta_file or warn "Could not open file '$fasta_file': $!" and next;

    my $header = '';
    my $sequence = '';
    my %seen_in_file;  # ファイル内で一意なシーケンスを追跡
    my $total_count = 0;
    my $unique_in_file = 0;

    while (my $line = <$in_fh>) {
        chomp $line;
        if ($line =~ /^>/) {    # ヘッダー行の場合
            # 現在のシーケンスを保存
            if ($header && $sequence) {
                $total_count++;
                if (!$seen_in_file{"$header\n$sequence"}++) {
                    $unique_in_file++;
                    $unique_sequences{"$header\n$sequence"}++;
                }
            }
            # 新しいヘッダーを開始
            $header = $line;
            $sequence = '';
        } else {                # シーケンス行の場合
            $sequence .= $line;
        }
    }

    # 最後のシーケンスを保存
    if ($header && $sequence) {
        $total_count++;
        if (!$seen_in_file{"$header\n$sequence"}++) {
            $unique_in_file++;
            $unique_sequences{"$header\n$sequence"}++;
        }
    }

    close $in_fh;

    # 統計情報を保存
    $file_stats{$fasta_file} = {
        total        => $total_count,
        unique_in_file => $unique_in_file,
    };
}

# ユニークなシーケンスを統合ファイルに書き出し
open my $out_fh, '>', $output_file or die "Could not create file '$output_file': $!";

foreach my $entry (keys %unique_sequences) {
    print $out_fh "$entry\n";
}

close $out_fh;

# 最終的なユニークタンパク質数
my $final_unique_count = keys %unique_sequences;

# 統計情報を表示・保存
open my $txt_fh, '>', $summary_txt or die "Could not create file '$summary_txt': $!";
open my $tsv_fh, '>', $summary_tsv or die "Could not create file '$summary_tsv': $!";

print "\nFile Statistics:\n";
print $txt_fh "File Statistics:\n";

# TSVヘッダー行
print $tsv_fh "File\tTotal sequences\tUnique in file\tDuplicates removed (in file)\n";

foreach my $file (sort keys %file_stats) {
    my $total          = $file_stats{$file}{total};
    my $unique_in_file = $file_stats{$file}{unique_in_file};
    my $duplicates_removed_in_file = $total - $unique_in_file;

    # 人間可読形式で出力
    print "File: $file\n";
    print "  Total sequences: $total\n";
    print "  Unique sequences (in file): $unique_in_file\n";
    print "  Duplicates removed (in file): $duplicates_removed_in_file\n\n";

    print $txt_fh "File: $file\n";
    print $txt_fh "  Total sequences: $total\n";
    print $txt_fh "  Unique sequences (in file): $unique_in_file\n";
    print $txt_fh "  Duplicates removed (in file): $duplicates_removed_in_file\n\n";

    # TSV形式で出力
    print $tsv_fh "$file\t$total\t$unique_in_file\t$duplicates_removed_in_file\n";
}

# 最終的なユニーク数を表示・保存
print "Final unique protein sequences in $output_file: $final_unique_count\n";
print $txt_fh "Final unique protein sequences in $output_file: $final_unique_count\n";

close $txt_fh;
close $tsv_fh;

print "Statistics saved to $summary_txt and $summary_tsv\n";
print "All unique protein sequences have been combined into $output_file\n";
