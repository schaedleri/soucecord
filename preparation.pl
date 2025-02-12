use strict;
use warnings;
use File::Path qw(make_path);

# 1. �o�̓t�H���_�̍쐬
my $output_dir = "./straightttttt";
make_path($output_dir) unless -d $output_dir;

# 2. ����FASTA�t�@�C���̓ǂݍ���
my $input_file = "protein.faa";
open(my $IN, "<", $input_file) or die "Cannot open file $input_file: $!";

my $OUT;
my $filename = "";
my $sequence = "";  # �V�[�P���X�f�[�^��ێ�����ϐ�

while (my $line = <$IN>) {
    chomp $line;
    
    if ($line =~ /^>(\S+)/) {  # �w�b�_�[�s�i�A�N�Z�b�V�����ԍ��j
        if ($OUT) {
            print $OUT "$sequence\n";  # 1�s�ɂ܂Ƃ߂ďo��
            close($OUT);  # �O�̃t�@�C�������
        }
        
        $filename = "$output_dir/$1.fasta";  # �A�N�Z�b�V�����ԍ����t�@�C������
        open($OUT, ">", $filename) or die "Cannot open output file $filename: $!";
        
        print $OUT "$line\n";  # �w�b�_�[�����̂܂܏o��
        $sequence = "";  # �V�[�P���X�����Z�b�g
    } else {
        $sequence .= $line;  # ���s���폜���ĘA��
    }
}

# �Ō�̃V�[�P���X���o��
if ($OUT) {
    print $OUT "$sequence\n";
    close($OUT);
}

close($IN);

print "finish\n";  # �����������b�Z�[�W





