use strict;
use warnings;
use File::Find;
use File::Basename;

# ���W���̃��[�g�f�B���N�g��
my $root_dir = '/source/bacteria_strain/';
# ������̏o�̓t�@�C��
my $output_file = 'all_proteins_unique.faa';
my $summary_txt = 'BS_statistics_summary.txt';
my $summary_tsv = 'BS_statistics_summary.tsv';

# �ċA�I��protein.faa��T���A���̓��e���i�[
my @fasta_files;
find(
    sub {
        if ($_ eq 'protein.faa') {
            push @fasta_files, $File::Find::name;
        }
    },
    $root_dir
);

# ���W���ʂ��m�F
if (!@fasta_files) {
    die "No 'protein.faa' files found in $root_dir\n";
}

print "Found ", scalar(@fasta_files), " protein.faa files.\n";

# ���j�[�N�ȃV�[�P���X��ۑ����邽�߂̃n�b�V��
my %unique_sequences;
my %file_stats;  # �e�t�@�C���̓��v���

# �e�t�@�C�����������ăV�[�P���X�����W
foreach my $fasta_file (@fasta_files) {
    open my $in_fh, '<', $fasta_file or warn "Could not open file '$fasta_file': $!" and next;

    my $header = '';
    my $sequence = '';
    my %seen_in_file;  # �t�@�C�����ň�ӂȃV�[�P���X��ǐ�
    my $total_count = 0;
    my $unique_in_file = 0;

    while (my $line = <$in_fh>) {
        chomp $line;
        if ($line =~ /^>/) {    # �w�b�_�[�s�̏ꍇ
            # ���݂̃V�[�P���X��ۑ�
            if ($header && $sequence) {
                $total_count++;
                if (!$seen_in_file{"$header\n$sequence"}++) {
                    $unique_in_file++;
                    $unique_sequences{"$header\n$sequence"}++;
                }
            }
            # �V�����w�b�_�[���J�n
            $header = $line;
            $sequence = '';
        } else {                # �V�[�P���X�s�̏ꍇ
            $sequence .= $line;
        }
    }

    # �Ō�̃V�[�P���X��ۑ�
    if ($header && $sequence) {
        $total_count++;
        if (!$seen_in_file{"$header\n$sequence"}++) {
            $unique_in_file++;
            $unique_sequences{"$header\n$sequence"}++;
        }
    }

    close $in_fh;

    # ���v����ۑ�
    $file_stats{$fasta_file} = {
        total        => $total_count,
        unique_in_file => $unique_in_file,
    };
}

# ���j�[�N�ȃV�[�P���X�𓝍��t�@�C���ɏ����o��
open my $out_fh, '>', $output_file or die "Could not create file '$output_file': $!";

foreach my $entry (keys %unique_sequences) {
    print $out_fh "$entry\n";
}

close $out_fh;

# �ŏI�I�ȃ��j�[�N�^���p�N����
my $final_unique_count = keys %unique_sequences;

# ���v����\���E�ۑ�
open my $txt_fh, '>', $summary_txt or die "Could not create file '$summary_txt': $!";
open my $tsv_fh, '>', $summary_tsv or die "Could not create file '$summary_tsv': $!";

print "\nFile Statistics:\n";
print $txt_fh "File Statistics:\n";

# TSV�w�b�_�[�s
print $tsv_fh "File\tTotal sequences\tUnique in file\tDuplicates removed (in file)\n";

foreach my $file (sort keys %file_stats) {
    my $total          = $file_stats{$file}{total};
    my $unique_in_file = $file_stats{$file}{unique_in_file};
    my $duplicates_removed_in_file = $total - $unique_in_file;

    # �l�ԉǌ`���ŏo��
    print "File: $file\n";
    print "  Total sequences: $total\n";
    print "  Unique sequences (in file): $unique_in_file\n";
    print "  Duplicates removed (in file): $duplicates_removed_in_file\n\n";

    print $txt_fh "File: $file\n";
    print $txt_fh "  Total sequences: $total\n";
    print $txt_fh "  Unique sequences (in file): $unique_in_file\n";
    print $txt_fh "  Duplicates removed (in file): $duplicates_removed_in_file\n\n";

    # TSV�`���ŏo��
    print $tsv_fh "$file\t$total\t$unique_in_file\t$duplicates_removed_in_file\n";
}

# �ŏI�I�ȃ��j�[�N����\���E�ۑ�
print "Final unique protein sequences in $output_file: $final_unique_count\n";
print $txt_fh "Final unique protein sequences in $output_file: $final_unique_count\n";

close $txt_fh;
close $tsv_fh;

print "Statistics saved to $summary_txt and $summary_tsv\n";
print "All unique protein sequences have been combined into $output_file\n";
