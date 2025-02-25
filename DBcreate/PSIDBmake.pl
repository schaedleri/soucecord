$cmd="makeblastdb -in BNRall.faa -dbtype prot -parse_seqids -out BNRall -logfile BNRall.log.txt -hash_index";
system ($cmd);