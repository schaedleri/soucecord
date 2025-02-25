use strict;
use warnings;
use File::Basename;
use Parallel::ForkManager;

# ���̓t�@�C���Əo�͐ݒ�
my $input_file = 'bacteria_strain.tsv';
my $failed_file = 'failed_microbes_bacteria.txt';
my $output_dir = 'bacteria_strain';

# �o�̓t�H���_�̍쐬
mkdir $output_dir unless -d $output_dir;

# �t�@�C���̃I�[�v��
open my $fh, '<', $input_file or die "Could not open file '$input_file': $!";
open my $failed_fh, '>>', $failed_file or die "Could not open file '$failed_file': $!"; # �ǋL���[�h

# ���񏈗��̐ݒ�
my $pm = Parallel::ForkManager->new(4);
my $line_count = `wc -l < $input_file` + 0;
my $processed = 0;

# �w�b�_�[�s���X�L�b�v
my $header = <$fh>;

# �e�s�̏���
while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^\s*$/;

    # �e����^�u��؂�ŕ���
    my @columns = split /\t/, $line;
    my $assembly_accession = $columns[0];  # Assembly Accession
    my $organism_name = $columns[2];      # Organism Name

    # �����������t�@�C�����Ɏg�p�ł���`���ɕϊ�
    $organism_name =~ s/[^\w]/_/g;
    my $output_file = "${output_dir}/${organism_name}_protein.zip";

    # �����t�@�C���`�F�b�N
    if (-e $output_file) {
        print "Skipping $organism_name (Accession: $assembly_accession): File already exists.\n";
        $processed++;
        next;
    }

    $pm->start and next;

    # �_�E�����[�h�R�}���h
    my $command = qq(datasets download genome accession $assembly_accession --assembly-level "complete" --assembly-source 'RefSeq' --reference --filename "$output_file" --include protein);

    # �R�}���h�̎��s
    my $result = system($command);

    # �Ď��s����
    if ($result != 0) {
        warn "First attempt failed for $organism_name (Accession: $assembly_accession). Retrying...\n";
        my $retry_command = qq(datasets download genome accession $assembly_accession --assembly-source 'RefSeq' --reference --filename "$output_file" --include protein);
        $result = system($retry_command);

        # �Ď��s�����s�����ꍇ
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

# �t�@�C�������
close $fh;
close $failed_fh;

print "Download completed. Check $output_dir and $failed_file for details.\n";
