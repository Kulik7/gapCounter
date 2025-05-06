version 1.0

workflow CountGaps {
  input {
    File assembly_fasta
  }

  call GrepCountNs {
    input:
      fasta_file = assembly_fasta
  }

  output {
    Int total_gap_length = GrepCountNs.total_gaps
  }
}

task GrepCountNs {
  input {
    File fasta_file
  }

  command <<< 
    if [[ "~{fasta_file}" == *.gz ]]; then
      gzip -cd "~{fasta_file}" | grep -v "^>" | tr -d -c 'Nn' | wc -c > gap_length.txt
    else
      cat "~{fasta_file}" | grep -v "^>" | tr -d -c 'Nn' | wc -c > gap_length.txt
    fi
  >>>

  output {
    Int total_gaps = read_int("gap_length.txt")
  }

  runtime {
    docker: "ubuntu:20.04"
    preemptible: 3  # Allows running on up to 3 preemptible VMs
    cpu: 1
    memory: "1G"
  }
}
