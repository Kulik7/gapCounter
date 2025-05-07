version 1.0

workflow count_gaps_parallel {
  input {
    File fasta
  }

  call split_fasta {
    input: fasta = fasta
  }

  scatter (seq in split_fasta.output_files) {
    call count_gaps {
      input: seq_file = seq
    }
  }

  call sum_counts {
    input: counts = count_gaps.count
  }

  output {
    Int total_gaps = sum_counts.total
  }
}

task split_fasta {
  input {
    File fasta
  }

  command <<<
    set -e
    mkdir splitted_fa
    if [[ "~{fasta}" == *.gz ]]; then
      gzip -cd "~{fasta}" | awk '/^>/ {f="splitted_fa/seq"++i".fa"} {print > f}'
    else
      cat "~{fasta}" | awk '/^>/ {f="splitted_fa/seq"++i".fa"} {print > f}'
    fi
    ls splitted_fa/*.fa > file_list.txt
  >>>

  output {
    Array[File] output_files = glob("splitted_fa/seq*.fa")
    # File list = "file_list.txt"
  }

  runtime {
    docker: "debian:bullseye-slim"
    preemptible: 2
  }
}

task count_gaps {
  input {
    File seq_file
  }

  command <<<
    echo "Counting gaps in file: ~{seq_file}"
    grep -v "^>" "~{seq_file}" | grep -o "N" | wc -l > gap_count.txt
  >>>

  output {
    Int count = read_int("gap_count.txt")
  }

  runtime {
    docker: "debian:bullseye-slim"
    preemptible: 2
  }
}

task sum_counts {
  input {
    Array[Int] counts
  }

  command <<< 
    total=0
    for c in ~{sep=' ' counts}; do
      total=$((total + c))
    done
    echo $total > total.txt
  >>>

  output {
    Int total = read_int("total.txt")
  }

  runtime {
    docker: "debian:bullseye-slim"
    preemptible: 2
  }
}
