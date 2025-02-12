#!/usr/bin/perl
use strict;
use warnings;

# �f�B���N�g���̐ݒ�
my $txt_dir = "/source/blast/Mucispirillum_schaedleri_ASF457/BS_result/hypothetical";
my $fasta_dir = "/source4/blast/Mucispirillum_schaedleri_ASF457";
my $output_dir = "/source/blast/Mucispirillum_schaedleri_ASF457/BS_result/PSIresult/";
my $db_path = "/source/DB/bacteria_strain_DB/DBall/BSDBall";

# �o�̓f�B���N�g���̍쐬
mkdir $output_dir unless -d $output_dir;

# txt�f�B���N�g�����̃t�@�C����ǂݍ���
opendir(my $dh, $txt_dir) or die "Cannot open directory $txt_dir: $!";
my @txt_files = grep { /\.txt$/ && -f "$txt_dir/$_" } readdir($dh);
closedir($dh);

# �etxt�t�@�C��������
foreach my $txt_file (@txt_files) {
    # �t�@�C�����̊g���q����菜��
    my ($base_name) = $txt_file =~ /^(.*)\.txt$/;

    # �Ή�����fasta�t�@�C�����m�F
    my $fasta_file = "$fasta_dir/$base_name.fasta";
    if (-e $fasta_file) {
        print "Processing $fasta_file with PSIBLAST...\n";

        # PSIBLAST�R�}���h���\�z
        my $output_file = "$output_dir/$base_name.txt";
        my $psiblast_cmd = "psiblast -query $fasta_file -db $db_path -max_target_seqs 100 ".
                           "-out $output_file -evalue 0.05 -num_iterations 3 ".
                           "-threshold 0.0001 -num_threads 10";

        # �R�}���h�����s
        system($psiblast_cmd) == 0
            or warn "Failed to run PSIBLAST for $fasta_file: $!";
    } else {
        warn "Warning: Corresponding fasta file $fasta_file not found for $txt_file.\n";
    }
}

print "All processing completed.\n";
