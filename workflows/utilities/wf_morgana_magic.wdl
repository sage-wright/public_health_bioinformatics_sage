version 1.0

import "../../tasks/quality_control/basic_statistics/task_consensus_qc.wdl" as consensus_qc_task
import "../../tasks/species_typing/betacoronavirus/task_pangolin.wdl" as pangolin
import "../../tasks/species_typing/lentivirus/task_quasitools.wdl" as quasitools
import "../../tasks/taxon_id/task_nextclade.wdl" as nextclade_task
import "../utilities/wf_organism_parameters.wdl" as set_organism_defaults
import "../utilities/wf_flu_track.wdl" as flu_track_wf

workflow morgana_magic {
  input {
    String samplename
    File assembly_fasta
    File read1
    File read2
    String taxon_id
    String seq_method
    # consensus qc
    Int? consensus_qc_cpu
    Int? consensus_qc_disk_size
    String? consensus_qc_docker
    Int? consensus_qc_memory
    # assembly metrics 
    Int? assembly_metrics_cpu
    Int? assembly_metrics_disk_size
    String? assembly_metrics_docker
    Int? assembly_metrics_memory
    # flu track - irma
    Int? irma_cpu
    Int? irma_disk_size
    String? irma_docker_image
    Boolean? irma_keep_ref_deletions
    Int? irma_memory
    # flu track - genoflu
    Int? genoflu_cpu
    File? genoflu_cross_reference
    Int? genoflu_disk_size
    String? genoflu_docker
    Int? genoflu_memory
    # flu track - abricate
    Int? abricate_flu_cpu
    Int? abricate_flu_disk_size
    String? abricate_flu_docker
    Int? abricate_flu_memory
    Int? abricate_flu_mincov
    Int? abricate_flu_minid
    # nextclade inputs
    Int? nextclade_cpu
    Int? nextclade_disk_size
    String? nextclade_docker_image
    Int? nextclade_memory
    Int? nextclade_output_parser_cpu
    Int? nextclade_output_parser_disk_size
    String? nextclade_output_parser_docker
    Int? nextclade_output_parser_memory
    # pangolin inputs
    Int? pangolin_cpu
    Int? pangolin_disk_size
    String? pangolin_docker_image
    Int? pangolin_memory
  }
  call set_organism_defaults.organism_parameters {
    input:
      taxon_id = taxon_id,
      organism = "unsupported",
      pangolin_docker_image = pangolin_docker_image
  }
  if (organism_parameters.standardized_organism != "unsupported") { # occurs in theiameta_panel
    call consensus_qc_task.consensus_qc {
      input:
        assembly_fasta = assembly_fasta,
        reference_genome = organism_parameters.reference,
        genome_length = organism_parameters.genome_length,
        cpu = consensus_qc_cpu,
        disk_size = consensus_qc_disk_size,
        docker = consensus_qc_docker,
        memory = consensus_qc_memory
    }
  }
  if (organism_parameters.standardized_organism == "flu") {
    call flu_track_wf.flu_track {
      input:
        samplename = samplename,
        read1 = read1,
        read2 = read2,
        seq_method = seq_method,
        standardized_organism = organism_parameters.standardized_organism,
        analyze_flu_antiviral_substitutions = false, # don't try to look for antiviral substitutions?? or maybe? not sure
        assembly_metrics_cpu = assembly_metrics_cpu,
        assembly_metrics_disk_size = assembly_metrics_disk_size,
        assembly_metrics_docker = assembly_metrics_docker,
        assembly_metrics_memory = assembly_metrics_memory,
        irma_cpu = irma_cpu,
        irma_disk_size = irma_disk_size,
        irma_docker_image = irma_docker_image,        
        irma_keep_ref_deletions = irma_keep_ref_deletions,
        irma_memory = irma_memory,
        genoflu_cross_reference = genoflu_cross_reference,
        genoflu_cpu = genoflu_cpu,
        genoflu_disk_size = genoflu_disk_size,
        genoflu_docker = genoflu_docker,
        genoflu_memory = genoflu_memory,
        abricate_flu_cpu = abricate_flu_cpu,
        abricate_flu_disk_size = abricate_flu_disk_size,
        abricate_flu_docker = abricate_flu_docker,
        abricate_flu_memory = abricate_flu_memory,
        abricate_flu_mincov = abricate_flu_mincov,
        abricate_flu_minid = abricate_flu_minid,
        nextclade_cpu = nextclade_cpu,
        nextclade_disk_size = nextclade_disk_size,
        nextclade_docker_image = nextclade_docker_image,
        nextclade_memory = nextclade_memory,
        nextclade_output_parser_cpu = nextclade_output_parser_cpu,
        nextclade_output_parser_disk_size = nextclade_output_parser_disk_size,
        nextclade_output_parser_docker = nextclade_output_parser_docker,
        nextclade_output_parser_memory = nextclade_output_parser_memory
    }
  }
  if (organism_parameters.standardized_organism == "sars-cov-2") {
    call pangolin.pangolin4 {
      input:
        samplename = samplename,
        fasta = assembly_fasta,
        docker = organism_parameters.pangolin_docker,
        cpu = pangolin_cpu,
        disk_size = pangolin_disk_size,
        memory = pangolin_memory
    }
  }
  if (organism_parameters.standardized_organism == "MPXV" || organism_parameters.standardized_organism == "sars-cov-2" || organism_parameters.standardized_organism == "rsv_a" || organism_parameters.standardized_organism == "rsv_b") { 
    call nextclade_task.nextclade_v3 {
      input:
        genome_fasta = assembly_fasta,
        dataset_name = organism_parameters.nextclade_dataset_name,
        dataset_tag = organism_parameters.nextclade_dataset_tag,
        cpu = nextclade_cpu,
        disk_size = nextclade_disk_size,
        docker = nextclade_docker_image,
        memory = nextclade_memory
    }
    call nextclade_task.nextclade_output_parser {
      input:
        nextclade_tsv = nextclade_v3.nextclade_tsv,
        organism = organism_parameters.standardized_organism,
        cpu = nextclade_output_parser_cpu,
        disk_size = nextclade_output_parser_disk_size,
        docker = nextclade_output_parser_docker,
        memory = nextclade_output_parser_memory
    }
  }
  output {
    String organism = organism_parameters.standardized_organism
    # Consensus QC outputs
    Int? number_N = consensus_qc.number_N
    Int? number_ATCG = consensus_qc.number_ATCG
    Int? number_Degenerate = consensus_qc.number_Degenerate
    Int? number_Total = consensus_qc.number_Total
    Float? percent_reference_coverage = consensus_qc.percent_reference_coverage
    # Pangolin outputs
    String? pango_lineage = pangolin4.pangolin_lineage
    String? pango_lineage_expanded = pangolin4.pangolin_lineage_expanded
    String? pangolin_conflicts = pangolin4.pangolin_conflicts
    String? pangolin_notes = pangolin4.pangolin_notes
    String? pangolin_assignment_version = pangolin4.pangolin_assignment_version
    File? pango_lineage_report = pangolin4.pango_lineage_report
    String? pangolin_docker = pangolin4.pangolin_docker
    String? pangolin_versions = pangolin4.pangolin_versions
    # Nextclade outputs for all organisms
    String nextclade_version = select_first([nextclade_v3.nextclade_version, flu_track.nextclade_version, ""])
    String nextclade_docker = select_first([nextclade_v3.nextclade_docker, flu_track.nextclade_docker, ""])
    # Nextclade outputs for non-flu
    File? nextclade_json = nextclade_v3.nextclade_json
    File? auspice_json = nextclade_v3.auspice_json
    File? nextclade_tsv = nextclade_v3.nextclade_tsv
    String nextclade_ds_tag = organism_parameters.nextclade_dataset_tag
    String? nextclade_aa_subs = nextclade_output_parser.nextclade_aa_subs
    String? nextclade_aa_dels = nextclade_output_parser.nextclade_aa_dels
    String? nextclade_clade = nextclade_output_parser.nextclade_clade
    String? nextclade_lineage = nextclade_output_parser.nextclade_lineage
    String? nextclade_qc = nextclade_output_parser.nextclade_qc
    # Nextclade outputs for flu HA
    File? nextclade_json_flu_ha = flu_track.nextclade_json_flu_ha
    File? auspice_json_flu_ha = flu_track.auspice_json_flu_ha
    File? nextclade_tsv_flu_ha = flu_track.nextclade_tsv_flu_ha
    String? nextclade_ds_tag_flu_ha = flu_track.nextclade_ds_tag_flu_ha
    String? nextclade_aa_subs_flu_ha = flu_track.nextclade_aa_subs_flu_ha
    String? nextclade_aa_dels_flu_ha = flu_track.nextclade_aa_dels_flu_ha
    String? nextclade_clade_flu_ha = flu_track.nextclade_clade_flu_ha
    String? nextclade_qc_flu_ha = flu_track.nextclade_qc_flu_ha
    # Nextclade outputs for flu NA
    File? nextclade_json_flu_na = flu_track.nextclade_json_flu_na
    File? auspice_json_flu_na = flu_track.auspice_json_flu_na
    File? nextclade_tsv_flu_na = flu_track.nextclade_tsv_flu_na
    String? nextclade_ds_tag_flu_na = flu_track.nextclade_ds_tag_flu_na
    String? nextclade_aa_subs_flu_na = flu_track.nextclade_aa_subs_flu_na
    String? nextclade_aa_dels_flu_na = flu_track.nextclade_aa_dels_flu_na
    String? nextclade_clade_flu_na = flu_track.nextclade_clade_flu_na
    String? nextclade_qc_flu_na = flu_track.nextclade_qc_flu_na
    # Flu IRMA Outputs
    String? irma_version = flu_track.irma_version
    String? irma_docker = flu_track.irma_docker
    String? irma_type = flu_track.irma_type
    String? irma_subtype = flu_track.irma_subtype
    String? irma_subtype_notes = flu_track.irma_subtype_notes
    # Flu GenoFLU Outputs
    String? genoflu_version = flu_track.genoflu_version
    String? genoflu_genotype = flu_track.genoflu_genotype
    String? genoflu_all_segments = flu_track.genoflu_all_segments
    File? genoflu_output_tsv = flu_track.genoflu_output_tsv
    # Flu Abricate Outputs
    String? abricate_flu_type = flu_track.abricate_flu_type
    String? abricate_flu_subtype =  flu_track.abricate_flu_subtype
    File? abricate_flu_results = flu_track.abricate_flu_results
    String? abricate_flu_database =  flu_track.abricate_flu_database
    String? abricate_flu_version = flu_track.abricate_flu_version
  }
}