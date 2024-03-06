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
    table = table.rename(columns={"entity:~{terra_table_name}_id": "sample"})
    sample_row = table[table["sample"] == "~{samplename}"]

    # Move elsewhere later - flu isnt in the gambit DB
    if 'abricate_flu_database' in sample_row.columns and sample_row["gambit_predicted_taxon"].iloc[0] != "":
      sample_row["gambit_predicted_taxon"] = 'Influenza A virus'

    # output dataframe as json
    sample_row.to_json("~{samplename}.json", orient="records")

    os.system("theiareporting -f ~{samplename}.pdf ~{samplename}.json")

    CODE
  >>>
  output {
    File sample_report_pdf = "~{samplename}.pdf"
  }
  runtime {
    docker: "us-docker.pkg.dev/general-theiagen/docker-private/theiareporting:0.0.6"
    memory: "2 GB"
    cpu: 2
    disks: "local-disk " + disk_size + " HDD"
    disk: disk_size + " GB"
    dx_instance_type: "mem1_ssd1_v2_x2"
  }
}
