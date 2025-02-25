#!/usr/bin/perl
use strict;
use warnings;

# ���͂Əo�̓t�@�C����
my $input_file = "all_proteins_unique.faa";
my $deduped_file = "BS_all_proteins_unique_deduped.faa";
my $output_prefix = "BS_all_proteins_unique_deduped";

# �d���폜�p�̃n�b�V��
my %seen = ();

# �d�����폜���Adeduped�t�@�C�����쐬
open(my $in_fh, '<', $input_file) or die "Cannot open $input_file: $!";
open(my $dedup_fh, '>', $deduped_file) or die "Cannot open $deduped_file: $!";

my $current_header = '';  # ���݂̃w�b�_�[��ۑ�����ϐ�
my $current_sequence = '';  # ���݂̃V�[�P���X��ۑ�����ϐ�

while (<$in_fh>) {
    chomp;
    if (/^>(\S+)/) {  # �w�b�_�[�s�����o
        my $accession = $1;

        # �O�̃G���g����ۑ�
        if ($current_header && !$seen{$current_header}) {
            print $dedup_fh "$current_header\n$current_sequence\n";
            $seen{$current_header} = 1;
        }

        # �V�����A�N�Z�b�V�����ԍ������ɋL�^����Ă��邩�m�F
        if (exists $seen{$accession}) {
            $current_header = '';  # �w�b�_�[�����Z�b�g
            $current_sequence = '';  # �V�[�P���X�����Z�b�g
            next;  # ���̃G���g���̓X�L�b�v
        }

        # �V�����w�b�_�[�ɐ؂�ւ�
        $current_header = $_;  # �w�b�_�[�s�S�̂�ۑ�
        $current_sequence = '';
        $seen{$accession} = 1;  # �A�N�Z�b�V�����ԍ����L�^
    } else {
        # �V�[�P���X�s��ǉ�
        $current_sequence .= $_;
    }
}

# �Ō�̃G���g����ۑ�
if ($current_header) {
    print $dedup_fh "$current_header\n$current_sequence\n";
}

close($in_fh);
close($dedup_fh);

print "�d���폜����: $deduped_file\n";

# 10��������
open(my $split_in_fh, '<', $deduped_file) or die "Cannot open $deduped_file: $!";

my @entries = ();  # �G���g�����i�[����z��
my $current_entry = "";  # ���݂̃G���g�����\�z����ϐ�

while (<$split_in_fh>) {
    chomp;
    if (/^>/) {  # �V�����G���g���̊J�n
        if ($current_entry) {
            push @entries, $current_entry;  # ���݂̃G���g����ۑ�
        }
        $current_entry = "$_\n";  # �w�b�_�[�s��ۑ�
    } else {
        $current_entry .= "$_\n";  # �V�[�P���X�s��ǉ�
    }
}
push @entries, $current_entry if $current_entry;  # �Ō�̃G���g����ۑ�

close($split_in_fh);

# ���������v�Z
my $num_splits = 10;
my $entries_per_file = int(@entries / $num_splits);
my $remainder = @entries % $num_splits;

# �������ăt�@�C���ɕۑ�
for my $i (0 .. $num_splits - 1) {
    my $output_file = "${output_prefix}${i}.faa";
    open(my $out_fh, '>', $output_file) or die "Cannot open $output_file: $!";

    my $start = $i * $entries_per_file;
    my $end = $start + $entries_per_file - 1;

    # �Ō�̃t�@�C���ɗ]���������
    $end += $remainder if $i == $num_splits - 1;

    for my $j ($start .. $end) {
        print $out_fh $entries[$j] if $j < @entries;  # �͈͊O��h��
    }

    close($out_fh);
    print "�����t�@�C�����쐬: $output_file\n";
}

print "�S�v���Z�X�����B�d���폜��̃t�@�C���� $deduped_file �ł��B\n";
