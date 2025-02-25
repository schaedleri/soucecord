#!/usr/bin/perl
use strict;
use warnings;

# 入力と出力ファイル名
my $input_file = "all_proteins_unique.faa";
my $deduped_file = "BS_all_proteins_unique_deduped.faa";
my $output_prefix = "BS_all_proteins_unique_deduped";

# 重複削除用のハッシュ
my %seen = ();

# 重複を削除し、dedupedファイルを作成
open(my $in_fh, '<', $input_file) or die "Cannot open $input_file: $!";
open(my $dedup_fh, '>', $deduped_file) or die "Cannot open $deduped_file: $!";

my $current_header = '';  # 現在のヘッダーを保存する変数
my $current_sequence = '';  # 現在のシーケンスを保存する変数

while (<$in_fh>) {
    chomp;
    if (/^>(\S+)/) {  # ヘッダー行を検出
        my $accession = $1;

        # 前のエントリを保存
        if ($current_header && !$seen{$current_header}) {
            print $dedup_fh "$current_header\n$current_sequence\n";
            $seen{$current_header} = 1;
        }

        # 新しいアクセッション番号が既に記録されているか確認
        if (exists $seen{$accession}) {
            $current_header = '';  # ヘッダーをリセット
            $current_sequence = '';  # シーケンスもリセット
            next;  # このエントリはスキップ
        }

        # 新しいヘッダーに切り替え
        $current_header = $_;  # ヘッダー行全体を保存
        $current_sequence = '';
        $seen{$accession} = 1;  # アクセッション番号を記録
    } else {
        # シーケンス行を追加
        $current_sequence .= $_;
    }
}

# 最後のエントリを保存
if ($current_header) {
    print $dedup_fh "$current_header\n$current_sequence\n";
}

close($in_fh);
close($dedup_fh);

print "重複削除完了: $deduped_file\n";

# 10分割処理
open(my $split_in_fh, '<', $deduped_file) or die "Cannot open $deduped_file: $!";

my @entries = ();  # エントリを格納する配列
my $current_entry = "";  # 現在のエントリを構築する変数

while (<$split_in_fh>) {
    chomp;
    if (/^>/) {  # 新しいエントリの開始
        if ($current_entry) {
            push @entries, $current_entry;  # 現在のエントリを保存
        }
        $current_entry = "$_\n";  # ヘッダー行を保存
    } else {
        $current_entry .= "$_\n";  # シーケンス行を追加
    }
}
push @entries, $current_entry if $current_entry;  # 最後のエントリを保存

close($split_in_fh);

# 分割数を計算
my $num_splits = 10;
my $entries_per_file = int(@entries / $num_splits);
my $remainder = @entries % $num_splits;

# 分割してファイルに保存
for my $i (0 .. $num_splits - 1) {
    my $output_file = "${output_prefix}${i}.faa";
    open(my $out_fh, '>', $output_file) or die "Cannot open $output_file: $!";

    my $start = $i * $entries_per_file;
    my $end = $start + $entries_per_file - 1;

    # 最後のファイルに余りを加える
    $end += $remainder if $i == $num_splits - 1;

    for my $j ($start .. $end) {
        print $out_fh $entries[$j] if $j < @entries;  # 範囲外を防ぐ
    }

    close($out_fh);
    print "分割ファイルを作成: $output_file\n";
}

print "全プロセス完了。重複削除後のファイルは $deduped_file です。\n";
