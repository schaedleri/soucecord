use strict;
use warnings;
use Parallel::ForkManager;
use File::Path qw(make_path);

# 最大プロセス数
my $max_processes = 10;

# フォークマネージャーの作成
my $pm = Parallel::ForkManager->new($max_processes);

# 対象ディレクトリの指定
my $target_dir = "/source/blast/Mucispirillum_schaedleri_ASF457/";
my @files = glob "$target_dir/*.fasta";

# 異なるローカルデータベースのリスト
my @dbs = (
    { db => "/share/bacteria_strain_DB/DB1/BSDB1", number => "DB1" },
    { db => "/share/bacteria_strain_DB/DB2/BSDB2", number => "DB2" },
    { db => "/share/bacteria_strain_DB/DB3/BSDB3", number => "DB3" },
    { db => "/share/bacteria_strain_DB/DB4/BSDB4", number => "DB4" },
    { db => "/share/bacteria_strain_DB/DB5/BSDB5", number => "DB5" },
    { db => "/share/bacteria_strain_DB/DB6/BSDB6", number => "DB6" },
    { db => "/share/bacteria_strain_DB/DB7/BSDB7", number => "DB7" },
    { db => "/share/bacteria_strain_DB/DB8/BSDB8", number => "DB8" },
    { db => "/share/bacteria_strain_DB/DB9/BSDB9", number => "DB9" },
    { db => "/share/bacteria_strain_DB/DB0/BSDB0", number => "DB10" }
);

# 結果出力ディレクトリの作成
my $result_dir = "$target_dir/BS_result";
make_path($result_dir);

foreach my $file (@files) {
    foreach my $db_info (@dbs) {
        $pm->start and next; # フォークプロセスの開始
        
        my $filename = $file;
        $filename =~ s/\.fasta$//;
        $filename =~ s|.*/||; # ディレクトリパスを除去
        
        my $db = $db_info->{db};
        my $db_number = $db_info->{number};
        
        my $output_file = "$result_dir/$filename.$db_number.txt";

        # 出力ファイルのチェックとスキップ条件の追加
        if (-e $output_file) {
            open my $fh, '<', $output_file;
            my $content = <$fh>;
            close $fh;
            if ($content && $content !~ /BLASTP 2\.12\.0\+/) {
                print "$output_file はすでに完了しています。スキップします。\n";
                $pm->finish; # 次のプロセスへ進む
                next;
            }
        }

        my $cmd = "blastp -query $file -db $db -max_target_seqs 20 -evalue 1e-10 -out $output_file";
        system $cmd;
        
        $pm->finish; # フォークプロセスの終了
    }
}

$pm->wait_all_children;

print "finish!";
