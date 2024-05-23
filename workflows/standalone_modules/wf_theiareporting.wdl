version 1.0

import "../../tasks/utilities/task_reporting.wdl" as theiareporting
import "../../tasks/task_versioning.wdl" as versioning

workflow theiareporting_wf {
  input {
             # Version Captures
    String theiaprok_illumina_pe_version
    String theiaprok_illumina_pe_analysis_date
    # Read Metadata
    String seq_platform
    # Taxon ID - gambit outputs
    String? gambit_predicted_taxon
    String? gambit_predicted_taxon_rank
    # NCBI-AMRFinderPlus Outputs
    String? amrfinderplus_amr_core_genes
    String? amrfinderplus_amr_plus_genes
    String? amrfinderplus_stress_genes
    String? amrfinderplus_virulence_genes
    String? amrfinderplus_amr_classes
    String? amrfinderplus_amr_subclasses
    String? amrfinderplus_db_version
    # MLST Typing
    String? ts_mlst_predicted_st
    String? ts_mlst_pubmlst_scheme
    # QC_Check Results
    String? qc_check
    # Ecoli Typing
    String? serotypefinder_serotype = merlin_magic.serotypefinder_serotype
    String? ectyper_version = merlin_magic.ectyper_version
    String? ectyper_predicted_serotype = merlin_magic.ectyper_predicted_serotype
    String? shigatyper_predicted_serotype = merlin_magic.shigatyper_predicted_serotype
    String? shigatyper_ipaB_presence_absence = merlin_magic.shigatyper_ipaB_presence_absence
    String? shigatyper_notes = merlin_magic.shigatyper_notes
    String? shigatyper_version = merlin_magic.shigatyper_version
    String? shigatyper_docker = merlin_magic.shigatyper_docker
    String? shigeifinder_docker = merlin_magic.shigeifinder_docker
    String? shigeifinder_version = merlin_magic.shigeifinder_version
    String? shigeifinder_ipaH_presence_absence = merlin_magic.shigeifinder_ipaH_presence_absence
    String? shigeifinder_num_virulence_plasmid_genes = merlin_magic.shigeifinder_num_virulence_plasmid_genes
    String? shigeifinder_cluster = merlin_magic.shigeifinder_cluster
    String? shigeifinder_serotype = merlin_magic.shigeifinder_serotype
    String? shigeifinder_O_antigen = merlin_magic.shigeifinder_O_antigen
    String? shigeifinder_H_antigen = merlin_magic.shigeifinder_H_antigen
    String? shigeifinder_notes = merlin_magic.shigeifinder_notes
    # ShigeiFinder outputs but for task that uses reads instead of assembly as input
    String? shigeifinder_docker_reads = merlin_magic.shigeifinder_docker
    String? shigeifinder_version_reads = merlin_magic.shigeifinder_version
    String? shigeifinder_ipaH_presence_absence_reads = merlin_magic.shigeifinder_ipaH_presence_absence
    String? shigeifinder_num_virulence_plasmid_genes_reads = merlin_magic.shigeifinder_num_virulence_plasmid_genes
    String? shigeifinder_cluster_reads = merlin_magic.shigeifinder_cluster
    String? shigeifinder_serotype_reads = merlin_magic.shigeifinder_serotype
    String? shigeifinder_O_antigen_reads = merlin_magic.shigeifinder_O_antigen
    String? shigeifinder_H_antigen_reads = merlin_magic.shigeifinder_H_antigen
    String? shigeifinder_notes_reads = merlin_magic.shigeifinder_notes
    # Shigella sonnei Typing
    File? sonneityping_mykrobe_report_csv = merlin_magic.sonneityping_mykrobe_report_csv
    File? sonneityping_mykrobe_report_json = merlin_magic.sonneityping_mykrobe_report_json
    File? sonneityping_final_report_tsv = merlin_magic.sonneityping_final_report_tsv
    String? sonneityping_mykrobe_version = merlin_magic.sonneityping_mykrobe_version
    String? sonneityping_mykrobe_docker = merlin_magic.sonneityping_mykrobe_docker
    String? sonneityping_species = merlin_magic.sonneityping_species
    String? sonneityping_final_genotype = merlin_magic.sonneityping_final_genotype
    String? sonneityping_genotype_confidence = merlin_magic.sonneityping_genotype_confidence
    String? sonneityping_genotype_name = merlin_magic.sonneityping_genotype_name
    # export taxon table output
    String? taxon_table_status = export_taxon_tables.status
    }
  call theiareporting.make_species_report {
    input:
      terra_table = terra_table,
      terra_table_name = terra_table_name,
      samplename = samplename,
      analyst_name = analyst_name
    }
  call versioning.version_capture {
    input:
  }
  output {
    File sample_report_pdf = make_species_report.sample_report_pdf
    }
 }
