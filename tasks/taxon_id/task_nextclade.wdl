version 1.0

task nextclade {
  meta {
    description: "Nextclade classification of one sample. Leaving optional inputs unspecified will use SARS-CoV-2 defaults."
  }
  input {
    File genome_fasta
    File? root_sequence
    File? auspice_reference_tree_json
    File? qc_config_json
    File? gene_annotations_gff
    File? pcr_primers_csv
    File? virus_properties
    String docker = "us-docker.pkg.dev/general-theiagen/nextstrain/nextclade:2.14.0"
    String dataset_name
    String dataset_reference
    String dataset_tag
    Int disk_size = 50
    Int memory = 4
    Int cpu = 2
  }
  String basename = basename(genome_fasta, ".fasta")
  command <<<
    NEXTCLADE_VERSION="$(nextclade --version)"
    echo $NEXTCLADE_VERSION > NEXTCLADE_VERSION

    nextclade dataset get --name="~{dataset_name}" --reference="~{dataset_reference}" --tag="~{dataset_tag}" -o nextclade_dataset_dir --verbose
    set -e
    nextclade run \
        --input-dataset=nextclade_dataset_dir/ \
        ~{"--input-root-seq " + root_sequence} \
        ~{"--input-tree " + auspice_reference_tree_json} \
        ~{"--input-qc-config " + qc_config_json} \
        ~{"--input-gene-map " + gene_annotations_gff} \
        ~{"--input-pcr-primers " + pcr_primers_csv} \
        ~{"--input-virus-properties " + virus_properties}  \
        --output-json "~{basename}".nextclade.json \
        --output-tsv  "~{basename}".nextclade.tsv \
        --output-tree "~{basename}".nextclade.auspice.json \
        --output-all=. \
        "~{genome_fasta}"
  >>>
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks:  "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB" # TES
    dx_instance_type: "mem1_ssd1_v2_x2"
    maxRetries: 3 
  }
  output {
    String nextclade_version = read_string("NEXTCLADE_VERSION")
    File nextclade_json = "~{basename}.nextclade.json"
    File auspice_json = "~{basename}.nextclade.auspice.json"
    File nextclade_tsv = "~{basename}.nextclade.tsv"
    String nextclade_docker = docker
    String nextclade_dataset_tag = "~{dataset_tag}"
  }
}

task nextclade_v3 {
  meta {
    description: "Nextclade classification of one sample. Leaving optional inputs unspecified will use SARS-CoV-2 defaults."
  }
  input {
    File genome_fasta
    File? auspice_reference_tree_json
    File? gene_annotations_gff
    File? nextclade_pathogen_json
    File? input_ref
    String docker = "us-docker.pkg.dev/general-theiagen/nextstrain/nextclade:3.3.1" 
    String dataset_name
    String verbosity = "warn" # other options are: "off" "error" "info" "debug" and "trace"
    String dataset_tag
    Int disk_size = 50
    Int memory = 4
    Int cpu = 2
  }
  String basename = basename(genome_fasta, ".fasta")
  command <<<
    # track version & print to log
    nextclade --version | tee NEXTCLADE_VERSION

    # --reference no longer used in v3. consolidated into --name and --tag
    nextclade dataset get \
      --name="~{dataset_name}" \
      --tag="~{dataset_tag}" \
      -o nextclade_dataset_dir \
      --verbosity ~{verbosity}

    # exit script/task upon error
    set -e

    # not necessary to include `--jobs <jobs>` in v3. Nextclade will use all available CPU threads by default. It's fast so I don't think we will need to change unless we see errors
    nextclade run \
      --input-dataset nextclade_dataset_dir/ \
      ~{"--input-ref " + input_ref} \
      ~{"--input-tree " + auspice_reference_tree_json} \
      ~{"--input-pathogen-json " + nextclade_pathogen_json} \
      ~{"--input-annotation " + gene_annotations_gff} \
      --output-json "~{basename}".nextclade.json \
      --output-tsv  "~{basename}".nextclade.tsv \
      --output-tree "~{basename}".nextclade.auspice.json \
      --output-all . \
      --verbosity ~{verbosity} \
      "~{genome_fasta}"
  >>>
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks:  "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB" # TES
    dx_instance_type: "mem1_ssd1_v2_x2"
    maxRetries: 3 
  }
  output {
    String nextclade_version = read_string("NEXTCLADE_VERSION")
    File nextclade_json = "~{basename}.nextclade.json"
    File auspice_json = "~{basename}.nextclade.auspice.json"
    File nextclade_tsv = "~{basename}.nextclade.tsv"
    String nextclade_docker = docker
    String nextclade_dataset_tag = "~{dataset_tag}"
  }
}

task nextclade_auto_predict {
  meta {
    description: "Nextclade classification of one sample. Automatically predicts the dataset name and tag."
  }
  input {
    File genome_fasta
    File? auspice_reference_tree_json
    File? gene_annotations_gff
    File? nextclade_pathogen_json
    File? input_ref
    String docker = "us-docker.pkg.dev/general-theiagen/nextstrain/nextclade:3.3.1"
    String verbosity = "warn" # other options are: "off" "error" "info" "debug" and "trace"
    Int disk_size = 50
    Int memory = 4
    Int cpu = 2
  }
  String basename = basename(genome_fasta, ".fasta")
  command <<<
    # track version & print to log
    nextclade --version | tee NEXTCLADE_VERSION

    # predict dataset name
    nextclade sort -r nextclade_dataset_output.tsv "~{genome_fasta}"
    dataset_name=$(cat nextclade_dataset_output.tsv | awk 'NR==2 {print $3}')

    echo "${dataset_name}" > NEXTCLADE_DATASET_NAME

    # exit script/task upon error
    set -e
    touch test.txt

    # if the dataset name is found, run nextclade
    if ! [[ "${dataset_name}" == "" ]]; then
      nextclade run \
        --dataset-name "${dataset_name}" \
        ~{"--input-ref " + input_ref} \
        ~{"--input-tree " + auspice_reference_tree_json} \
        ~{"--input-pathogen-json " + nextclade_pathogen_json} \
        ~{"--input-annotation " + gene_annotations_gff} \
        --output-json "~{basename}".nextclade.json \
        --output-tsv  "~{basename}".nextclade.tsv \
        --output-tree "~{basename}".nextclade.auspice.json \
        --output-all . \
        --verbosity ~{verbosity} \
        "~{genome_fasta}"

      # by default, use the latest tag
      nextclade dataset list --name "${dataset_name}" --json > dataset_tag.json
      grep -A 2 '"version": {' dataset_tag.json | grep '"tag"' | head -n 1 | sed 's/.*"tag": *"\([^"]*\)".*/\1/' > NEXTCLADE_DATASET_TAG
    else
      echo "Dataset name could not be predicted" > NEXTCLADE_DATASET_NAME
      echo "Dataset name could not be predicted" > NEXTCLADE_DATASET_TAG
      echo "Dataset name could not be predicted" > "~{basename}.nextclade.json"
      echo "Dataset name could not be predicted" > "~{basename}.nextclade.auspice.json"
      echo "Dataset name could not be predicted" > "~{basename}.nextclade.tsv"
    fi
  >>>
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks:  "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB" # TES
    dx_instance_type: "mem1_ssd1_v2_x2"
    maxRetries: 3
  }
  output {
    String nextclade_version = read_string("NEXTCLADE_VERSION")
    File nextclade_json = "~{basename}.nextclade.json"
    File auspice_json = "~{basename}.nextclade.auspice.json"
    File nextclade_tsv = "~{basename}.nextclade.tsv"
    String nextclade_docker = docker
    String nextclade_dataset_name = read_string("NEXTCLADE_DATASET_NAME")
    String nextclade_dataset_tag = read_string("NEXTCLADE_DATASET_TAG")
  }
}

task nextclade_output_parser {
  meta {
    description: "Python and bash codeblocks for parsing the output files from Nextclade."
  }
  input {
    File nextclade_tsv
    String docker = "us-docker.pkg.dev/general-theiagen/python/python:3.8.18-slim"
    Int disk_size = 50
    Int memory = 4
    Int cpu = 2
    String? organism
  }
  command <<<
    # Set WDL input variable to input.tsv file
    cat "~{nextclade_tsv}" > input.tsv
    touch TAMIFLU_AASUBS
    
    # Parse outputs using python3
    python3 <<CODE
    import csv
    import codecs

    # Function to write 'None' into all required files
    def write_none_to_files():
        with codecs.open("NEXTCLADE_CLADE", 'w') as file:
            file.write("None")
        with codecs.open("NEXTCLADE_DATASET_TAG", 'w') as file:
            file.write("None")
        with codecs.open("NEXTCLADE_AASUBS", 'w') as file:
            file.write("None")
        with codecs.open("NEXTCLADE_AADELS", 'w') as file:
            file.write("None")
        with codecs.open("NEXTCLADE_LINEAGE", 'w') as file:
            file.write("None")
        with codecs.open("NEXTCLADE_QC", 'w') as file:
            file.write("None")

    # Check if the file contains "Dataset name could not be predicted"
    with codecs.open("./input.tsv", 'r') as tsv_file:
        file_content = tsv_file.read()

    if "Dataset name could not be predicted" in file_content or not file_content.strip():
        # If file is empty or contains the specific phrase, skip processing and write 'None' to files
        print("Empty input file or dataset name could not be predicted. Skipping processing.")
        write_none_to_files()
    else:
        # Proceed with processing the tsv file
        with codecs.open("./input.tsv", 'r') as tsv_file:
            tsv_reader = csv.reader(tsv_file, delimiter="\t")
            tsv_data = list(tsv_reader)

            if len(tsv_data) == 1:
                tsv_data.append(['NA'] * len(tsv_data[0]))
            tsv_dict = dict(zip(tsv_data[0], tsv_data[1]))

            # Combine 'clade_nextstrain' and 'clade_who' column if sars-cov-2
            if ("~{organism}" == "sars-cov-2"):
                with codecs.open("NEXTCLADE_CLADE", 'wt') as Nextclade_Clade:
                    nc_clade = tsv_dict['clade_nextstrain']
                    who_clade = tsv_dict['clade_who']
                    if (nc_clade != who_clade) and (nc_clade != '') and (who_clade != ''):
                        nc_clade = nc_clade + " (" + who_clade + ")"
                    if nc_clade == '':
                        nc_clade = 'NA'
                    Nextclade_Clade.write(nc_clade)
            else:
                with codecs.open("NEXTCLADE_CLADE", 'wt') as Nextclade_Clade:
                    nc_clade = tsv_dict['clade']
                    if nc_clade == '':
                        nc_clade = 'NA'
                    Nextclade_Clade.write(nc_clade)

            with codecs.open("NEXTCLADE_AASUBS", 'wt') as Nextclade_AA_Subs:
                nc_aa_subs = tsv_dict['aaSubstitutions']
                if nc_aa_subs == '':
                    nc_aa_subs = 'NA'
                Nextclade_AA_Subs.write(nc_aa_subs)

            with codecs.open("NEXTCLADE_AADELS", 'wt') as Nextclade_AA_Dels:
                nc_aa_dels = tsv_dict['aaDeletions']
                if nc_aa_dels == '':
                    nc_aa_dels = 'NA'
                Nextclade_AA_Dels.write(nc_aa_dels)

            with codecs.open("NEXTCLADE_LINEAGE", 'wt') as Nextclade_Lineage:
                if 'lineage' in tsv_dict:
                    nc_lineage = tsv_dict['lineage']
                    if nc_lineage is None:
                        nc_lineage = ""
                elif 'Nextclade_pango' in tsv_dict:
                    nc_lineage = tsv_dict['Nextclade_pango']
                    if nc_lineage is None:
                        nc_lineage = ""
                else:
                    nc_lineage = ""
                Nextclade_Lineage.write(nc_lineage)

            with codecs.open("NEXTCLADE_QC", 'wt') as Nextclade_QC:
                nc_qc = tsv_dict['qc.overallStatus']
                if nc_qc == '':
                    nc_qc = 'NA'
                Nextclade_QC.write(nc_qc)
    CODE
  >>>
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks:  "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    dx_instance_type: "mem1_ssd1_v2_x2"
    maxRetries: 3
  }
  output {
    String nextclade_clade = read_string("NEXTCLADE_CLADE")
    String nextclade_aa_subs = read_string("NEXTCLADE_AASUBS")
    String nextclade_aa_dels = read_string("NEXTCLADE_AADELS")
    String nextclade_lineage = read_string("NEXTCLADE_LINEAGE")
    String nextclade_qc = read_string("NEXTCLADE_QC")
  }
}

task nextclade_add_ref {
  meta {
    description: "Nextclade task to add samples to either a user specified or a nextclade reference tree."
  }
  input {
    File genome_fasta
    File? reference_tree_json
    File? nextclade_pathogen_json
    File? gene_annotations_gff
    File? input_ref
    String docker = "us-docker.pkg.dev/general-theiagen/nextstrain/nextclade:3.3.1"
    String dataset_name
    String? dataset_tag
    String verbosity = "warn" # other options are: "off" "error" "info" "debug" and "trace"
    Int disk_size = 100
    Int memory = 4
    Int cpu = 2
  }
  String basename = basename(genome_fasta, ".fasta")
  command <<<
    # track version & print to log
    nextclade --version | tee NEXTCLADE_VERSION

    echo "DEBUG: downloading nextclade dataset..."
    nextclade dataset get \
      --name="~{dataset_name}" \
      ~{"--tag " + dataset_tag} \
      -o nextclade_dataset_dir \
      --verbosity ~{verbosity}

    # If no reference sequence is provided, use the reference tree from the dataset
    if [ -z "~{reference_tree_json}" ]; then
      echo "Default dataset reference tree JSON will be used"
      cp -v nextclade_dataset_dir/tree.json reference_tree.json
    else
      echo "User reference tree JSON will be used"
      cp -v ~{reference_tree_json} reference_tree.json
    fi

    tree_json="reference_tree.json"

    set -e
    echo "DEBUG: running nextclade..."
    nextclade run \
      --input-dataset nextclade_dataset_dir/ \
      --input-tree ${tree_json} \
      ~{"--input-pathogen-json " + nextclade_pathogen_json} \
      ~{"--input-annotation " + gene_annotations_gff} \
      ~{"--input-ref " + input_ref} \
      --output-json "~{basename}".nextclade.json \
      --output-tsv  "~{basename}".nextclade.tsv \
      --output-tree "~{basename}".nextclade.auspice.json \
      --output-all=. \
      "~{genome_fasta}"
  >>>
  runtime {
    docker: "~{docker}"
    memory: memory + " GB"
    cpu: cpu
    disks:  "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    dx_instance_type: "mem1_ssd1_v2_x2"
    maxRetries: 3
  }
  output {
    String nextclade_version = read_string("NEXTCLADE_VERSION")
    File nextclade_json = "~{basename}.nextclade.json"
    File auspice_json = "~{basename}.nextclade.auspice.json"
    File nextclade_tsv = "~{basename}.nextclade.tsv"
    String nextclade_docker = docker
    File netclade_ref_tree = "reference_tree.json"
  }
}