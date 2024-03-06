version 1.0

import "../../tasks/utilities/task_reporting.wdl" as theiareporting
import "../../tasks/task_versioning.wdl" as versioning

workflow theiareporting_wf {
  input {
          File terra_table
          String terra_table_name
          String samplename
          String analyst_name
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
