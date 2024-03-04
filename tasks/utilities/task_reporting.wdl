version 1.0

task make_species_report {
  meta {
    description: "Generate species specific report for a single sample"
  }
  input {
    File terra_table
    String terra_table_name
    String samplename
    String analyst_name
    File? amrfinderplus_all_report

    Int disk_size = 100
  }
  command <<<
    python3 <<CODE
    import pandas as pd
    import numpy as np
    import os

    ### Processing of data
    table = pd.read_csv("~{terra_table}", delimiter='\t', header=0, dtype={"~{terra_table_name}_id": 'str'}) # ensure sample_id is always a string
    table["analyst_name"] = "~{analyst_name}"
    table = table.rename(columns={"~{terra_table_name}_id": "sample"})
    sample_row = table[table["sample"] == "~{samplename}"]

    # Move elsewhere later - flu isnt in the gambit DB
    if 'abricate_flu_database' in sample_row.columns and sample_row["gambit_predicted_taxon"].iloc[0] != "":
      sample_row["gambit_predicted_taxon"] = 'Influenza A virus'

    # output dataframe as json
    sample_row.to_json("~{samplename}.json", orient="records")

    if os.path.exists("~{amrfinderplus_all_report}"):
      os.system("theiareporting -a ~{amrfinderplus_all_report} -o ~{samplename}.pdf  ~{samplename}.json")
    else:
      os.system("theiareporting -o ~{samplename}.pdf  ~{samplename}.json")

    CODE
  >>>
  output {
    File species_report_json = "~{samplename}.json" # this is for internal use for testing only
    File species_report_pdf = "~{samplename}.pdf"
  }
  runtime {
    docker: "quay.io/theiagen/theiagenreporting:v0.0.1"
    memory: "2 GB"
    cpu: 2
    disks: "local-disk " + disk_size + " HDD"
    disk: disk_size + " GB"
    dx_instance_type: "mem1_ssd1_v2_x2"
  }
}
