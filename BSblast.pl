use strict;
use warnings;
use Parallel::ForkManager;
use File::Path qw(make_path);

# �ő�v���Z�X��
my $max_processes = 10;

# �t�H�[�N�}�l�[�W���[�̍쐬
my $pm = Parallel::ForkManager->new($max_processes);

# �Ώۃf�B���N�g���̎w��
my $target_dir = "/source/blast/Mucispirillum_schaedleri_ASF457/";
my @files = glob "$target_dir/*.fasta";

# �قȂ郍�[�J���f�[�^�x�[�X�̃��X�g
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

# ���ʏo�̓f�B���N�g���̍쐬
my $result_dir = "$target_dir/BS_result";
make_path($result_dir);

foreach my $file (@files) {
    foreach my $db_info (@dbs) {
        $pm->start and next; # �t�H�[�N�v���Z�X�̊J�n
        
        my $filename = $file;
        $filename =~ s/\.fasta$//;
        $filename =~ s|.*/||; # �f�B���N�g���p�X������
        
        my $db = $db_info->{db};
        my $db_number = $db_info->{number};
        
        my $output_file = "$result_dir/$filename.$db_number.txt";

        # �o�̓t�@�C���̃`�F�b�N�ƃX�L�b�v�����̒ǉ�
        if (-e $output_file) {
            open my $fh, '<', $output_file;
            my $content = <$fh>;
            close $fh;
            if ($content && $content !~ /BLASTP 2\.12\.0\+/) {
                print "$output_file �͂��łɊ������Ă��܂��B�X�L�b�v���܂��B\n";
                $pm->finish; # ���̃v���Z�X�֐i��
                next;
            }
        }

        my $cmd = "blastp -query $file -db $db -max_target_seqs 20 -evalue 1e-10 -out $output_file";
        system $cmd;
        
        $pm->finish; # �t�H�[�N�v���Z�X�̏I��
    }
}

$pm->wait_all_children;

print "finish!";
