use strict;
use warnings;
use File::Path qw(make_path);

# 1. 出力フォルダの作成
my $output_dir = "./straightttttt";
make_path($output_dir) unless -d $output_dir;

# 2. 入力FASTAファイルの読み込み
my $input_file = "protein.faa";
open(my $IN, "<", $input_file) or die "Cannot open file $input_file: $!";

my $OUT;
my $filename = "";
my $sequence = "";  # シーケンスデータを保持する変数

while (my $line = <$IN>) {
    chomp $line;
    
    if ($line =~ /^>(\S+)/) {  # ヘッダー行（アクセッション番号）
        if ($OUT) {
            print $OUT "$sequence\n";  # 1行にまとめて出力
            close($OUT);  # 前のファイルを閉じる
        }
        
        $filename = "$output_dir/$1.fasta";  # アクセッション番号をファイル名に
        open($OUT, ">", $filename) or die "Cannot open output file $filename: $!";
        
        print $OUT "$line\n";  # ヘッダーをそのまま出力
        $sequence = "";  # シーケンスをリセット
    } else {
        $sequence .= $line;  # 改行を削除して連結
    }
}

# 最後のシーケンスを出力
if ($OUT) {
    print $OUT "$sequence\n";
    close($OUT);
}

close($IN);

print "finish\n";  # 処理完了メッセージ





