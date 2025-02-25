#!/usr/bin/perl
use strict;
use warnings;
use File::Path qw(make_path);

# ���̓t�@�C���̃v���t�B�b�N�X
my $input_prefix = "BS_all_proteins_unique_deduped";
my $output_base_dir = "/source/bacteria_strain_DB";

# �J��Ԃ������Ńf�[�^�x�[�X���쐬
for my $i (0 .. 9) {
    my $input_file = "${input_prefix}${i}.faa";
    my $output_dir = "${output_base_dir}/DB${i}";
    my $output_db = "${output_dir}/BSDB${i}";
    my $log_file = "${output_dir}/BSDB${i}.log.txt";

    # �o�̓f�B���N�g�����쐬
    if (!-d $output_dir) {
        make_path($output_dir) or die "Cannot create directory $output_dir: $!";
        print "�f�B���N�g���쐬: $output_dir\n";
    }

    # makeblastdb�R�}���h���\�z
    my $cmd = "makeblastdb -in $input_file -dbtype prot -parse_seqids -out $output_db -logfile $log_file -hash_index";
    print "�R�}���h���s��: $cmd\n";

    # �R�}���h�����s
    system($cmd) == 0 or die "Error running makeblastdb for $input_file: $!";
    print "�f�[�^�x�[�X�쐬����: $output_db\n";
}

print "�S�f�[�^�x�[�X�쐬�����B\n";
